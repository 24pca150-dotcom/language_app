<?php

namespace App\Http\Controllers;

use App\Models\Chapter;
use App\Models\SubChapter;
use App\Services\ProgressService;
use Illuminate\Http\Request;

class ProgressController extends Controller
{
    protected $progressService;

    public function __construct(ProgressService $progressService)
    {
        $this->progressService = $progressService;
    }

    /**
     * Get unlocked status for all chapters in a level.
     */
    public function getLevelProgress(Request $request, $levelId)
    {
        $userId = $request->user_id ?? 1; // Demo default
        $chapters = Chapter::where('level_id', $levelId)
            ->orderBy('sort_order')
            ->get();

        $progress = [];
        foreach ($chapters as $chapter) {
            $progress[] = [
                'chapter_id' => $chapter->id,
                'is_unlocked' => $this->progressService->canAccessChapter($userId, $chapter->id),
                'is_completed' => $this->progressService->isChapterCompleted($userId, $chapter->id),
            ];
        }

        return response()->json($progress);
    }

    /**
     * Check if user can access a specific chapter.
     */
    public function checkAccess(Request $request)
    {
        $request->validate([
            'chapter_id' => 'required|integer',
            'user_id' => 'required|integer',
        ]);

        $canAccess = $this->progressService->canAccessChapter($request->user_id, $request->chapter_id);

        return response()->json([
            'can_access' => $canAccess,
            'message' => $canAccess ? 'Access granted' : 'This chapter is locked. Complete mandatory assessments of previous chapter.'
        ]);
    }
}
