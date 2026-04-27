<?php

namespace App\Http\Controllers;

use App\Models\Level;
use App\Models\Chapter;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LevelChapterController extends Controller
{
    /**
     * List all chapters mapped to a level.
     */
    public function index($levelId)
    {
        $level = Level::findOrFail($levelId);
        $chapters = $level->chapters()->orderBy('level_chapter.sort_order')->get();
        return response()->json($chapters);
    }

    /**
     * Map chapter(s) to a level.
     */
    public function store(Request $request, $levelId)
    {
        $validated = $request->validate([
            'chapter_ids' => 'required|array|min:1',
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

        $level->chapters()->syncWithoutDetaching($syncData);

        return response()->json(['message' => 'Chapters mapped successfully'], 201);
    }

    /**
     * List all levels mapped to a chapter.
     */
    public function getLevelsByChapter($chapterId)
    {
        $chapter = Chapter::findOrFail($chapterId);
        $levels = $chapter->levels()->get();
        return response()->json($levels);
    }

    /**
     * Map level(s) to a chapter.
     */
    public function syncLevels(Request $request, $chapterId)
    {
        $validated = $request->validate([
            'level_ids' => 'required|array',
            'level_ids.*' => 'required|exists:levels,id',
        ]);

        $chapter = Chapter::findOrFail($chapterId);
        
        $syncData = [];
        foreach ($validated['level_ids'] as $levelId) {
            $syncData[$levelId] = [
                'is_active' => true
            ];
        }

        $chapter->levels()->sync($syncData);

        return response()->json(['message' => 'Levels synced successfully']);
    }

    /**
     * Remove a chapter mapping from a level.
     */
    public function destroy($levelId, $chapterId)
    {
        $level = Level::findOrFail($levelId);
        $level->chapters()->detach($chapterId);
        return response()->noContent();
    }

    /**
     * Update the sort order of mapped chapters.
     */
    public function updateOrder(Request $request, $levelId)
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
