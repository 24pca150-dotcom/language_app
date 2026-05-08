<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\Content;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ContentController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        return Content::with(['chapters', 'attachments'])->orderBy('sort_order')->get();
    }

    /**
     * Upload a single file and return its public URL.
     */
    public function upload(Request $request)
    {
        $request->validate([
            'file' => 'required|file|max:51200', // 50MB max
        ]);

        $file = $request->file('file');
        $originalName = $file->getClientOriginalName();
        $extension = strtolower($file->getClientOriginalExtension());
        
        // Generate Unique ID (filename on server)
        $uniqueId = uniqid() . '-' . time() . '.' . $extension;

        // Determine subfolder by extension
        $folder = match(true) {
            in_array($extension, ['jpg','jpeg','png','gif','webp','svg']) => 'images',
            in_array($extension, ['mp4','mov','avi','mkv','webm'])        => 'videos',
            $extension === 'pdf'                                          => 'pdfs',
            in_array($extension, ['doc','docx'])                          => 'docs',
            in_array($extension, ['xls','xlsx'])                          => 'xlsx',
            in_array($extension, ['ppt','pptx'])                          => 'ppts',
            default                                                       => 'files',
        };

        $path = $file->storeAs("contents/{$folder}", $uniqueId, 'public');
        $url  = Storage::disk('public')->url($path);

        return response()->json([
            'url'           => $url,
            'unique_id'     => $uniqueId,
            'original_name' => $originalName,
            'extension'     => $extension,
            'size'          => $this->formatSizeUnits($file->getSize()),
            'type'          => $folder,
        ]);
    }

    private function formatSizeUnits($bytes)
    {
        if ($bytes >= 1048576) {
            $bytes = number_format($bytes / 1048576, 2) . ' MB';
        } elseif ($bytes >= 1024) {
            $bytes = number_format($bytes / 1024, 2) . ' KB';
        } elseif ($bytes > 1) {
            $bytes = $bytes . ' bytes';
        } elseif ($bytes == 1) {
            $bytes = $bytes . ' byte';
        } else {
            $bytes = '0 bytes';
        }

        return $bytes;
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name'           => 'required|string|max:255',
            'chapter_ids'    => 'nullable|array',
            'chapter_ids.*'  => 'exists:chapters,id',
            'sort_order'     => 'integer',
            'is_active'      => 'boolean',
            'text_content'   => 'nullable|string',
            'urls'           => 'nullable|array',
            'urls.*'         => 'nullable|string',
            'attachments'    => 'nullable|array',
            'attachments.*'  => 'nullable|array',
        ]);

        $validated['external_url'] = !empty($validated['urls'])
            ? array_values(array_filter($validated['urls']))
            : null;
        unset($validated['urls']);

        $content = Content::create($validated);

        if ($request->has('chapter_ids')) {
            $content->chapters()->sync($request->chapter_ids ?? []);
        }

        if ($request->has('attachments')) {
            foreach ($request->attachments as $attachment) {
                if (!empty($attachment['unique_id'])) {
                    $content->attachments()->create([
                        'unique_id'     => $attachment['unique_id'],
                        'original_name' => $attachment['original_name'] ?? '',
                        'alias_name'    => $attachment['alias_name'] ?? $attachment['original_name'],
                        'file_size'     => $attachment['size'] ?? '',
                        'file_extension'=> $attachment['extension'] ?? '',
                    ]);
                }
            }
        }

        return $content->load(['chapters', 'attachments']);
    }

    /**
     * Display the specified resource.
     */
    public function show(Content $content)
    {
        return $content->load(['chapters', 'attachments']);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, Content $content)
    {
        $validated = $request->validate([
            'name'           => 'required|string|max:255',
            'chapter_ids'    => 'nullable|array',
            'chapter_ids.*'  => 'exists:chapters,id',
            'sort_order'     => 'integer',
            'is_active'      => 'boolean',
            'text_content'   => 'nullable|string',
            'urls'           => 'nullable|array',
            'urls.*'         => 'nullable|string',
            'attachments'    => 'nullable|array',
            'attachments.*'  => 'nullable|array',
        ]);

        $validated['external_url'] = !empty($validated['urls'])
            ? array_values(array_filter($validated['urls']))
            : null;
        unset($validated['urls']);

        $content->update($validated);

        if ($request->has('chapter_ids')) {
            $content->chapters()->sync($request->chapter_ids ?? []);
        }

        if ($request->has('attachments')) {
            // Get current unique IDs to avoid duplicates
            $currentUniqueIds = $content->attachments->pluck('unique_id')->toArray();
            $newUniqueIds = [];

            foreach ($request->attachments as $attachment) {
                if (!empty($attachment['unique_id'])) {
                    $newUniqueIds[] = $attachment['unique_id'];
                    if (!in_array($attachment['unique_id'], $currentUniqueIds)) {
                        $content->attachments()->create([
                            'unique_id'     => $attachment['unique_id'],
                            'original_name' => $attachment['original_name'] ?? '',
                            'alias_name'    => $attachment['alias_name'] ?? $attachment['original_name'],
                            'file_size'     => $attachment['size'] ?? '',
                            'file_extension'=> $attachment['extension'] ?? '',
                        ]);
                    } else {
                        // Update alias_name if changed
                        $content->attachments()->where('unique_id', $attachment['unique_id'])->update([
                            'alias_name' => $attachment['alias_name'] ?? $attachment['original_name']
                        ]);
                    }
                }
            }

            // Mark missing as deleted
            $content->attachments()->whereNotIn('unique_id', $newUniqueIds)->update(['is_deleted' => true]);
        }

        return $content->load(['chapters', 'attachments']);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Content $content)
    {
        $content->delete();
        return response()->noContent();
    }
}
