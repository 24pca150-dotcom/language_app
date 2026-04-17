<?php

namespace App\Http\Controllers;

use App\Models\SubChapter;
use Illuminate\Http\Request;

class SubChapterController extends Controller
{
    public function index(Request $request)
    {
        $query = SubChapter::with('chapter.level');

        if ($request->has('chapter_id')) {
            $query->where('chapter_id', $request->chapter_id);
        }

        return response()->json($query->orderBy('sort_order')->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'chapter_id' => 'required|exists:chapters,id',
            'name' => 'required|string|max:255',
            'content_type' => 'required|in:text,video,file,image,slide_view',
            'content' => 'nullable|string',
            'content_meta' => 'nullable|array',
            'sort_order' => 'nullable|integer|min:0',
            'is_active' => 'boolean',
        ]);

        $subChapter = SubChapter::create($validated);

        return response()->json($subChapter->load(['chapter.level', 'assessments']), 201);
    }

    public function show(SubChapter $subChapter)
    {
        return response()->json($subChapter->load(['chapter.level', 'assessments']));
    }

    public function update(Request $request, SubChapter $subChapter)
    {
        $validated = $request->validate([
            'chapter_id' => 'required|exists:chapters,id',
            'name' => 'required|string|max:255',
            'content_type' => 'required|in:text,video,file,image,slide_view',
            'content' => 'nullable|string',
            'content_meta' => 'nullable|array',
            'sort_order' => 'nullable|integer|min:0',
            'is_active' => 'boolean',
        ]);

        $subChapter->update($validated);

        return response()->json($subChapter->load('chapter.level'));
    }

    public function destroy(SubChapter $subChapter)
    {
        $subChapter->delete();
        return response()->noContent();
    }
}
