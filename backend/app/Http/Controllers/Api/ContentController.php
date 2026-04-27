<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Content;
use Illuminate\Http\Request;

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
     * Store a newly created resource in.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'chapter_ids' => 'nullable|array',
            'chapter_ids.*' => 'exists:chapters,id',
            'sort_order' => 'integer',
            'is_active' => 'boolean',
            'text_content' => 'nullable|string',
            'external_url' => 'nullable|url',
            'image' => 'nullable|string',
            'video' => 'nullable|string',
            'pdf' => 'nullable|string',
            'doc' => 'nullable|string',
            'xlsx' => 'nullable|string',
            'ppt' => 'nullable|string',
        ]);

        $content = Content::create($validated);
        
        if ($request->has('chapter_ids')) {
            $content->chapters()->sync($request->chapter_ids);
        }

        return $content->load('chapters');
    }

    /**
     * Display the specified resource.
     */
    public function show(Content $content)
    {
        return $content;
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, Content $content)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'chapter_ids' => 'nullable|array',
            'chapter_ids.*' => 'exists:chapters,id',
            'sort_order' => 'integer',
            'is_active' => 'boolean',
            'text_content' => 'nullable|string',
            'external_url' => 'nullable|url',
            'image' => 'nullable|string',
            'video' => 'nullable|string',
            'pdf' => 'nullable|string',
            'doc' => 'nullable|string',
            'xlsx' => 'nullable|string',
            'ppt' => 'nullable|string',
        ]);

        $content->update($validated);
        
        if ($request->has('chapter_ids')) {
            $content->chapters()->sync($request->chapter_ids);
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
