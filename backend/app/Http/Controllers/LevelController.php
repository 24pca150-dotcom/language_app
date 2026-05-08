<?php

namespace App\Http\Controllers;

use App\Models\Level;
use App\Models\Chapter;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LevelController extends Controller
{
    public function index(Request $request)
    {
        $query = Level::query();

        return response()->json($query->orderBy('sort_order')->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'required|string|max:50|unique:levels,code',
            'description' => 'nullable|string',
            'objective_listening' => 'nullable|string',
            'objective_speaking' => 'nullable|string',
            'objective_reading' => 'nullable|string',
            'objective_writing' => 'nullable|string',
            'estimated_hours' => 'nullable|numeric|min:0',
            'sort_order' => 'nullable|integer|min:0',
            'is_active' => 'boolean',
        ]);

        $level = Level::create($validated);

        return response()->json($level, 201);
    }

    public function show(Level $level)
    {
        return response()->json($level->load(['assessments.questions.options']));
    }

    public function update(Request $request, Level $level)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'required|string|max:50|unique:levels,code,' . $level->id,
            'description' => 'nullable|string',
            'objective_listening' => 'nullable|string',
            'objective_speaking' => 'nullable|string',
            'objective_reading' => 'nullable|string',
            'objective_writing' => 'nullable|string',
            'estimated_hours' => 'nullable|numeric|min:0',
            'sort_order' => 'nullable|integer|min:0',
            'is_active' => 'boolean',
        ]);

        $level->update($validated);

        return response()->json($level);
    }

    public function destroy(Level $level)
    {
        $level->delete();
        return response()->noContent();
    }

    /**
     * List all chapters mapped to a level.
     */
    public function getChapters($levelId)
    {
        $level = Level::findOrFail($levelId);
        $chapters = $level->chapters()->orderBy('level_chapter.sort_order')->get();
        return response()->json($chapters);
    }

    /**
     * Map chapter(s) to a level.
     */
    public function mapChapters(Request $request, $levelId)
    {
        $validated = $request->validate([
            'chapter_ids' => 'nullable|array',
            'chapter_ids.*' => 'required|exists:chapters,id',
        ]);

        $level = Level::findOrFail($levelId);
        
        $syncData = [];
        foreach ($validated['chapter_ids'] as $index => $chapterId) {
            $syncData[$chapterId] = [
                'sort_order' => $index,
                'is_active' => true
            ];
        }

        $level->chapters()->sync($syncData);

        return response()->json(['message' => 'Chapters mapped successfully'], 201);
    }

    /**
     * Remove a chapter mapping from a level.
     */
    public function unmapChapter($levelId, $chapterId)
    {
        $level = Level::findOrFail($levelId);
        $level->chapters()->detach($chapterId);
        return response()->noContent();
    }

    /**
     * Update the sort order of mapped chapters.
     */
    public function reorderChapters(Request $request, $levelId)
    {
        $validated = $request->validate([
            'orders' => 'required|array',
            'orders.*.chapter_id' => 'required|exists:chapters,id',
            'orders.*.sort_order' => 'required|integer',
        ]);

        foreach ($validated['orders'] as $order) {
            DB::table('level_chapter')
                ->where('level_id', $levelId)
                ->where('chapter_id', $order['chapter_id'])
                ->update(['sort_order' => $order['sort_order']]);
        }

        return response()->json(['message' => 'Order updated successfully']);
    }
}
