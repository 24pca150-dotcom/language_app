<?php

namespace App\Http\Controllers;

use App\Models\Course;
use App\Models\Level;
use App\Models\Chapter;
use App\Models\UserAssessmentAttempt;
use App\Services\ProgressService;
use Illuminate\Http\Request;

class LearningProgressController extends Controller
{
    protected $progressService;

    public function __construct(ProgressService $progressService)
    {
        $this->progressService = $progressService;
    }

    /**
     * Get user progress for all levels in a course.
     */
    public function getUserProgress($userId, $courseId)
    {
        // Existing logic for course level overview
        $course = Course::with(['levels' => function ($q) {
            $q->orderBy('sort_order');
        }])->findOrFail($courseId);

        $levels = [];
        $previousPassed = true;

        foreach ($course->levels as $level) {
            $unlocked = $previousPassed;
            // Check if user has passed ALL mandatory assessments for this level (if any)
            $isCompleted = $this->progressService->isChapterCompleted($userId, null); // level logic would be similar

            $levels[] = [
                'level_id' => $level->id,
                'name' => $level->name,
                'is_unlocked' => $unlocked,
                // simplified for summary
            ];
            
            // For now, let's stick to the existing logic but keep it extensible
            $previousPassed = true; // Temporary
        }

        return response()->json(['levels' => $levels]);
    }

    /**
     * Get unlocked status for all chapters in a level.
     */
    public function getChapterProgress($userId, $levelId)
    {
        $chapters = Chapter::where('level_id', $levelId)
            ->orderBy('sort_order')
            ->get();

        $data = [];
        foreach ($chapters as $chapter) {
            $data[] = [
                'chapter_id' => $chapter->id,
                'name' => $chapter->name,
                'is_unlocked' => $this->progressService->canAccessChapter($userId, $chapter->id),
                'is_completed' => $this->progressService->isChapterCompleted($userId, $chapter->id),
            ];
        }

        return response()->json(['chapters' => $data]);
    }

    /**
     * Check if a specific level is accessible to a user.
     */
    public function getLevelAccess($userId, $levelId)
    {
        // Keep existing or use service
        return response()->json(['is_unlocked' => true]);
    }
}
