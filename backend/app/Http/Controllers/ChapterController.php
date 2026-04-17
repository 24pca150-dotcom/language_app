<?php

namespace App\Http\Controllers;

use App\Models\Chapter;
use Illuminate\Http\Request;

class ChapterController extends Controller
{
    public function index(Request $request)
    {
        $query = Chapter::with(['level.course', 'subChapters']);

        if ($request->has('level_id')) {
            $query->where('level_id', $request->level_id);
        }

        return response()->json($query->orderBy('sort_order')->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'level_id' => 'required|exists:levels,id',
            'name' => 'required|string|max:255',
            'code' => 'required|string|max:50|unique:chapters,code',
            'description' => 'nullable|string',
            'content_type' => 'nullable|string|max:50',
            'content' => 'nullable|string',
            'content_meta' => 'nullable|array',
            'sort_order' => 'nullable|integer|min:0',
            'is_active' => 'boolean',
        ]);

        $chapter = Chapter::create($validated);

        return response()->json($chapter->load(['level.course', 'subChapters', 'assessments']), 201);
    }

    public function show(Chapter $chapter)
    {
        return response()->json($chapter->load(['level.course', 'subChapters', 'assessments']));
    }

    public function update(Request $request, Chapter $chapter)
    {
        $validated = $request->validate([
            'level_id' => 'required|exists:levels,id',
            'name' => 'required|string|max:255',
            'code' => 'required|string|max:50|unique:chapters,code,' . $chapter->id,
            'description' => 'nullable|string',
            'content_type' => 'nullable|string|max:50',
            'content' => 'nullable|string',
            'content_meta' => 'nullable|array',
            'sort_order' => 'nullable|integer|min:0',
            'is_active' => 'boolean',
        ]);

        $chapter->update($validated);

        return response()->json($chapter->load(['level.course', 'subChapters']));
    }

    public function destroy(Chapter $chapter)
    {
        $chapter->delete();
        return response()->noContent();
    }
}
