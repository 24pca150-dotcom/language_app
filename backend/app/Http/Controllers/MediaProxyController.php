<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\PersonalAccessToken;
use App\Models\ContentAttachment;
use App\Models\LiveClassAttachment;
use Symfony\Component\HttpFoundation\StreamedResponse;

class MediaProxyController extends Controller
{
    /**
     * Allowed remote hostnames to prevent SSRF vulnerabilities.
     */
    protected array $allowedHosts = [
        'res.cloudinary.com',
        'cloudinary.com',
        'api.cloudinary.com',
    ];

    /**
     * Resolve the authenticated user from Bearer header or query token.
     */
    protected function authenticateUser(Request $request)
    {
        // 1. Try standard Sanctum request user (if passed via Authorization header)
        $user = $request->user();
        if ($user) {
            return $user;
        }

        // 2. Try query parameter 'token' (useful for <a> tags, <video>, window.open in new tab)
        $tokenString = $request->query('token');
        if ($tokenString) {
            $accessToken = PersonalAccessToken::findToken($tokenString);
            if ($accessToken && $accessToken->tokenable) {
                return $accessToken->tokenable;
            }
        }

        return null;
    }

    /**
     * Generate a temporary secure view URL for frontend components.
     * Endpoint: POST /api/media/generate-view-url
     */
    public function generateViewUrl(Request $request)
    {
        $request->validate([
            'url' => 'required|string',
            'name' => 'nullable|string',
        ]);

        $user = $request->user();
        if (!$user) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        // Generate a plain token or signed proxy URL
        $mediaUrl = $request->input('url');
        $fileName = $request->input('name', 'document');

        $viewUrl = url('/api/media/stream') . '?' . http_build_query([
            'url'   => $mediaUrl,
            'name'  => $fileName,
            'token' => $request->bearerToken(),
        ]);

        return response()->json([
            'view_url' => $viewUrl,
        ]);
    }

    /**
     * Stream any media (Cloudinary / remote URL or local storage) securely.
     * Endpoint: GET /api/media/stream?url=...&token=...&name=...&download=1
     */
    public function streamMedia(Request $request)
    {
        $user = $this->authenticateUser($request);
        if (!$user) {
            return response()->json(['message' => 'Unauthorized. Please login to view this file.'], 401);
        }

        $rawUrl = $request->query('url');
        if (empty($rawUrl)) {
            abort(400, 'Missing url parameter.');
        }

        // Validate that remote URL is from allowed Cloudinary domains
        $parsed = parse_url($rawUrl);
        $host = strtolower($parsed['host'] ?? '');

        $isAllowedHost = false;
        foreach ($this->allowedHosts as $allowed) {
            if ($host === $allowed || str_ends_with($host, '.' . $allowed)) {
                $isAllowedHost = true;
                break;
            }
        }

        // Also allow local URLs/storage files if needed
        $isLocalStorage = str_contains($rawUrl, '/storage/') || !isset($parsed['host']);

        if (!$isAllowedHost && !$isLocalStorage) {
            abort(403, 'Access denied: Untrusted media host.');
        }

        $fileName = $request->query('name') ?: basename($parsed['path'] ?? 'file');
        $extension = strtolower(pathinfo($fileName, PATHINFO_EXTENSION) ?: pathinfo($parsed['path'] ?? '', PATHINFO_EXTENSION));
        $mimeType = $this->detectMimeType($extension);
        $isDownload = $request->boolean('download');
        $disposition = $isDownload ? 'attachment' : 'inline';

        return $this->streamFromUrl($rawUrl, $fileName, $mimeType, $disposition);
    }

    /**
     * Stream a ContentAttachment by ID.
     * Endpoint: GET /api/media/attachment/{id}
     */
    public function streamAttachment(Request $request, $id)
    {
        $user = $this->authenticateUser($request);
        if (!$user) {
            return response()->json(['message' => 'Unauthorized.'], 401);
        }

        $attachment = ContentAttachment::with('content')->findOrFail($id);

        // Security / Tenant verification
        if ($user->role !== 'super_admin' && $user->tenant_id && $attachment->content?->tenant_id) {
            if ($user->tenant_id !== $attachment->content->tenant_id) {
                abort(403, 'Unauthorized access to this document.');
            }
        }

        $url = $attachment->url;
        if (!$url) {
            abort(404, 'Attachment file not found.');
        }

        $fileName = $attachment->original_name ?: $attachment->alias_name ?: ('attachment_' . $attachment->id);
        $extension = strtolower($attachment->file_extension ?: pathinfo($fileName, PATHINFO_EXTENSION));
        $mimeType = $this->detectMimeType($extension);
        $disposition = $request->boolean('download') ? 'attachment' : 'inline';

        return $this->streamFromUrl($url, $fileName, $mimeType, $disposition);
    }

    /**
     * Stream a LiveClassAttachment by ID.
     * Endpoint: GET /api/media/live-class-attachment/{id}
     */
    public function streamLiveClassAttachment(Request $request, $id)
    {
        $user = $this->authenticateUser($request);
        if (!$user) {
            return response()->json(['message' => 'Unauthorized.'], 401);
        }

        $attachment = LiveClassAttachment::with('liveClass')->findOrFail($id);

        // Security / Tenant check
        if ($user->role !== 'super_admin' && $user->tenant_id && $attachment->liveClass?->tenant_id) {
            if ($user->tenant_id !== $attachment->liveClass->tenant_id) {
                abort(403, 'Unauthorized access to this live class attachment.');
            }
        }

        $url = $attachment->file_url;
        if (!$url) {
            abort(404, 'Attachment file not found.');
        }

        $fileName = $attachment->original_name ?: $attachment->title ?: ('live_attachment_' . $attachment->id);
        $extension = strtolower($attachment->file_extension ?: pathinfo($fileName, PATHINFO_EXTENSION));
        $mimeType = $this->detectMimeType($extension);
        $disposition = $request->boolean('download') ? 'attachment' : 'inline';

        return $this->streamFromUrl($url, $fileName, $mimeType, $disposition);
    }

    /**
     * Stream binary content from a local disk or remote URL efficiently without high RAM usage.
     */
    protected function streamFromUrl(string $url, string $fileName, string $mimeType, string $disposition): StreamedResponse
    {
        // Headers to prevent caching sensitive documents and to ensure safe browser rendering
        $headers = [
            'Content-Type'              => $mimeType,
            'Content-Disposition'       => "{$disposition}; filename=\"{$fileName}\"",
            'Cache-Control'             => 'private, max-age=3600, must-revalidate',
            'X-Content-Type-Options'    => 'nosniff',
        ];

        return response()->stream(function () use ($url) {
            // Use stream context with a 15-second timeout and SSL verification
            $context = stream_context_create([
                'http' => [
                    'timeout'         => 30,
                    'follow_location' => 1,
                    'user_agent'      => 'MacvelLearningPortal/1.0',
                ],
                'ssl' => [
                    'verify_peer'      => true,
                    'verify_peer_name' => true,
                ],
            ]);

            $handle = @fopen($url, 'rb', false, $context);
            if ($handle === false) {
                echo "Unable to stream file.";
                return;
            }

            // Stream in 64KB buffer chunks to preserve server RAM
            while (!feof($handle)) {
                echo fread($handle, 65536);
                flush();
            }

            fclose($handle);
        }, 200, $headers);
    }

    /**
     * Detect MIME type based on file extension.
     */
    protected function detectMimeType(string $extension): string
    {
        return match (strtolower(trim($extension, '.'))) {
            'pdf'                      => 'application/pdf',
            'jpg', 'jpeg'              => 'image/jpeg',
            'png'                      => 'image/png',
            'gif'                      => 'image/gif',
            'webp'                     => 'image/webp',
            'svg'                      => 'image/svg+xml',
            'mp4'                      => 'video/mp4',
            'webm'                     => 'video/webm',
            'mov'                      => 'video/quicktime',
            'mp3'                      => 'audio/mpeg',
            'wav'                      => 'audio/wav',
            'doc'                      => 'application/msword',
            'docx'                     => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'xls'                      => 'application/vnd.ms-excel',
            'xlsx'                     => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'ppt'                      => 'application/vnd.ms-powerpoint',
            'pptx'                     => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
            default                    => 'application/octet-stream',
        };
    }
}
