<?php

namespace App\Http\Controllers;

use App\Models\LiveClass;
use App\Models\LiveClassAttachment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Carbon\Carbon;

class LiveClassController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $query = LiveClass::with('attachments');

        if ($user->role !== 'super_admin') {
            $query->where('tenant_id', $user->tenant_id);
        }

        $classes = $query->orderBy('start_time', 'desc')->get();
        return response()->json($classes);
    }

    public function upcoming(Request $request)
    {
        $user = $request->user();
        $query = LiveClass::with('attachments');

        if ($user->role !== 'super_admin') {
            $query->where('tenant_id', $user->tenant_id);
        }

        // Show live or future classes, or classes started within last 3 hours
        $threshold = Carbon::now()->subHours(3);
        $classes = $query->where(function ($q) use ($threshold) {
            $q->where('status', 'live')
              ->orWhere(function ($sub) use ($threshold) {
                  $sub->where('status', '!=', 'completed')
                      ->where('start_time', '>=', $threshold);
              });
        })
        ->orderByRaw("CASE WHEN status = 'live' THEN 0 ELSE 1 END")
        ->orderBy('start_time', 'asc')
        ->get();

        return response()->json($classes);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'meeting_link' => 'required|url|max:500',
            'instructor_name' => 'nullable|string|max:255',
            'start_time' => 'required|date',
            'duration_minutes' => 'nullable|integer|min:5|max:480',
            'status' => 'nullable|string|in:scheduled,live,completed,cancelled'
        ]);

        $user = $request->user();

        // Detect platform
        $link = strtolower($validated['meeting_link']);
        $platform = 'other';
        if (str_contains($link, 'meet.google.com')) {
            $platform = 'google_meet';
        } elseif (str_contains($link, 'zoom.us')) {
            $platform = 'zoom';
        } elseif (str_contains($link, 'teams.microsoft.com') || str_contains($link, 'teams.live.com')) {
            $platform = 'teams';
        } elseif (str_contains($link, 'youtube.com') || str_contains($link, 'youtu.be')) {
            $platform = 'youtube';
        }

        $liveClass = LiveClass::create([
            'tenant_id' => $user->role === 'super_admin' ? null : $user->tenant_id,
            'title' => $validated['title'],
            'description' => $validated['description'] ?? null,
            'meeting_link' => $validated['meeting_link'],
            'platform' => $platform,
            'instructor_name' => $validated['instructor_name'] ?? ($user->name ?? 'Instructor'),
            'start_time' => Carbon::parse($validated['start_time']),
            'duration_minutes' => $validated['duration_minutes'] ?? 60,
            'status' => $validated['status'] ?? 'scheduled',
            'created_by' => $user->id
        ]);

        // Process attachments if uploaded during creation
        if ($request->hasFile('files')) {
            $this->processFileUploads($request->file('files'), $liveClass, $user->id);
        }

        $liveClass->load('attachments');
        return response()->json($liveClass, 201);
    }

    public function update(Request $request, LiveClass $liveClass)
    {
        $validated = $request->validate([
            'title' => 'sometimes|required|string|max:255',
            'description' => 'nullable|string',
            'meeting_link' => 'sometimes|required|url|max:500',
            'instructor_name' => 'nullable|string|max:255',
            'start_time' => 'sometimes|required|date',
            'duration_minutes' => 'nullable|integer|min:5|max:480',
            'status' => 'nullable|string|in:scheduled,live,completed,cancelled'
        ]);

        if (isset($validated['meeting_link'])) {
            $link = strtolower($validated['meeting_link']);
            $platform = 'other';
            if (str_contains($link, 'meet.google.com')) {
                $platform = 'google_meet';
            } elseif (str_contains($link, 'zoom.us')) {
                $platform = 'zoom';
            } elseif (str_contains($link, 'teams.microsoft.com') || str_contains($link, 'teams.live.com')) {
                $platform = 'teams';
            } elseif (str_contains($link, 'youtube.com') || str_contains($link, 'youtu.be')) {
                $platform = 'youtube';
            }
            $validated['platform'] = $platform;
        }

        if (isset($validated['start_time'])) {
            $validated['start_time'] = Carbon::parse($validated['start_time']);
        }

        $liveClass->update($validated);

        if ($request->hasFile('files')) {
            $this->processFileUploads($request->file('files'), $liveClass, $request->user()->id);
        }

        $liveClass->load('attachments');
        return response()->json($liveClass);
    }

    public function uploadAttachments(Request $request, LiveClass $liveClass)
    {
        $request->validate([
            'files' => 'required|array',
            'files.*' => 'required|file|max:102400', // max 100MB per file
        ]);

        $created = $this->processFileUploads($request->file('files'), $liveClass, $request->user()->id);
        $liveClass->load('attachments');

        return response()->json([
            'message' => 'Files uploaded successfully',
            'attachments' => $liveClass->attachments
        ]);
    }

    public function deleteAttachment(LiveClassAttachment $attachment)
    {
        if ($attachment->file_path && Storage::disk('public')->exists($attachment->file_path)) {
            Storage::disk('public')->delete($attachment->file_path);
        }

        $attachment->delete();
        return response()->json(['message' => 'Attachment deleted successfully']);
    }

    public function destroy(LiveClass $liveClass)
    {
        // Delete all attached files from disk
        foreach ($liveClass->attachments as $attachment) {
            if ($attachment->file_path && Storage::disk('public')->exists($attachment->file_path)) {
                Storage::disk('public')->delete($attachment->file_path);
            }
        }

        $liveClass->delete();
        return response()->json(['message' => 'Live class deleted successfully']);
    }

    private function processFileUploads(array $files, LiveClass $liveClass, int $userId): array
    {
        $records = [];
        foreach ($files as $file) {
            $origName = $file->getClientOriginalName();
            $ext = strtolower($file->getClientOriginalExtension());
            $bytes = $file->getSize();

            $fileType = match(true) {
                in_array($ext, ['pdf']) => 'pdf',
                in_array($ext, ['mp4', 'mov', 'avi', 'mkv', 'webm']) => 'video',
                in_array($ext, ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg']) => 'image',
                in_array($ext, ['mp3', 'wav', 'ogg', 'm4a', 'aac', 'flac']) => 'audio',
                in_array($ext, ['doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt']) => 'document',
                default => 'other',
            };

            if ($bytes >= 1048576) {
                $fileSize = number_format($bytes / 1048576, 2) . ' MB';
            } elseif ($bytes >= 1024) {
                $fileSize = number_format($bytes / 1024, 1) . ' KB';
            } else {
                $fileSize = $bytes . ' B';
            }

            $path = $file->store("live_classes/{$liveClass->id}", 'public');

            $records[] = LiveClassAttachment::create([
                'live_class_id' => $liveClass->id,
                'title' => pathinfo($origName, PATHINFO_FILENAME),
                'file_type' => $fileType,
                'file_path' => $path,
                'original_name' => $origName,
                'file_extension' => $ext,
                'file_size' => $fileSize,
                'uploaded_by' => $userId,
            ]);
        }

        return $records;
    }
}
