<?php

namespace App\Http\Controllers\Api;

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
        return Content::with('chapters')->orderBy('sort_order')->get();
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
        $extension = strtolower($file->getClientOriginalExtension());

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

        $path = $file->store("contents/{$folder}", 'public');
        $url  = Storage::disk('public')->url($path);

        return response()->json([
            'url'       => $url,
            'name'      => $file->getClientOriginalName(),
            'extension' => $extension,
            'type'      => $folder,
        ]);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name'         => 'required|string|max:255',
            'chapter_ids'  => 'nullable|array',
            'chapter_ids.*'=> 'exists:chapters,id',
            'sort_order'   => 'integer',
            'is_active'    => 'boolean',
            'text_content' => 'nullable|string',
            'urls'         => 'nullable|array',
            'urls.*'       => 'nullable|string',
            'image'        => 'nullable|array',
            'video'        => 'nullable|array',
            'pdf'          => 'nullable|array',
            'doc'          => 'nullable|array',
            'xlsx'         => 'nullable|array',
            'ppt'          => 'nullable|array',
        ]);

        $validated['external_url'] = !empty($validated['urls'])
            ? array_values(array_filter($validated['urls']))
            : null;
        unset($validated['urls']);

        $content = Content::create($validated);

        if ($request->has('chapter_ids')) {
            $content->chapters()->sync($request->chapter_ids ?? []);
        }

        return $content->load('chapters');
    }

    /**
     * Display the specified resource.
     */
    public function show(Content $content)
    {
        return $content->load('chapters');
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, Content $content)
    {
        $validated = $request->validate([
            'name'         => 'required|string|max:255',
            'chapter_ids'  => 'nullable|array',
            'chapter_ids.*'=> 'exists:chapters,id',
            'sort_order'   => 'integer',
            'is_active'    => 'boolean',
            'text_content' => 'nullable|string',
            'urls'         => 'nullable|array',
            'urls.*'       => 'nullable|string',
            'image'        => 'nullable|array',
            'video'        => 'nullable|array',
            'pdf'          => 'nullable|array',
            'doc'          => 'nullable|array',
            'xlsx'         => 'nullable|array',
            'ppt'          => 'nullable|array',
        ]);

        $validated['external_url'] = !empty($validated['urls'])
            ? array_values(array_filter($validated['urls']))
            : null;
        unset($validated['urls']);

        // Only apply fields present in request. If a file field is missing, it means it's unchanged or empty.
        $content->update($validated);

        if ($request->has('chapter_ids')) {
            $content->chapters()->sync($request->chapter_ids ?? []);
        }

        return $content->load('chapters');
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
