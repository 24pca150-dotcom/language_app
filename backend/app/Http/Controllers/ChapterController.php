<?php

namespace App\Http\Controllers;

use App\Models\Chapter;
use Illuminate\Http\Request;

class ChapterController extends Controller
{
    public function index(Request $request)
    {
        $query = Chapter::query();

        if ($request->has('level_id')) {
            $levelId = $request->level_id;
            $query->whereHas('levels', function ($q) use ($levelId) {
                $q->where('levels.id', $levelId);
            })->with(['levels' => function ($q) use ($levelId) {
                $q->where('levels.id', $levelId);
            }]);
        }

        return response()->json($query->with(['contents.attachments', 'assessments'])->orderBy('sort_order')->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'required|string|max:50|unique:chapters,code',
            'description' => 'nullable|string',
            'sort_order' => 'nullable|integer|min:0',
            'is_active' => 'boolean',
        ]);

        $chapter = Chapter::create($validated);

        return response()->json($chapter->load(['contents.attachments', 'assessments']), 201);
    }

    public function show(Chapter $chapter)
    {
        return response()->json($chapter->load(['contents.attachments', 'assessments']));
    }

    public function update(Request $request, Chapter $chapter)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'required|string|max:50|unique:chapters,code,' . $chapter->id,
            'description' => 'nullable|string',
            'sort_order' => 'nullable|integer|min:0',
            'is_active' => 'boolean',
        ]);

        $chapter->update($validated);

        return response()->json($chapter);
    }

    public function destroy(Chapter $chapter)
    {
        $chapter->delete();
        return response()->noContent();
    }

    /**
     * List all levels mapped to a chapter.
     */
    public function getLevels($chapterId)
    {
        $chapter = Chapter::findOrFail($chapterId);
        $levels = $chapter->levels()->orderBy('level_chapter.sort_order')->get();
        return response()->json($levels);
    }

    /**
     * Map level(s) to a chapter.
     */
    public function mapLevels(Request $request, $chapterId)
    {
        $validated = $request->validate([
            'level_ids' => 'nullable|array',
            'level_ids.*' => 'required|exists:levels,id',
        ]);

        $chapter = Chapter::findOrFail($chapterId);
        
        $syncData = [];
        foreach ($validated['level_ids'] as $index => $levelId) {
            $syncData[$levelId] = [
                'sort_order' => $index,
                'is_active' => true
            ];
        }

        $chapter->levels()->sync($syncData);

        return response()->json(['message' => 'Levels mapped successfully'], 201);
    }
}
