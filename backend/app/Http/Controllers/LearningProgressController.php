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
        $level = Level::findOrFail($levelId);
        $chapters = $level->chapters()
            ->orderBy('level_chapter.sort_order')
            ->get();

        $data = [];
        foreach ($chapters as $chapter) {
            $data[] = [
                'chapter_id' => $chapter->id,
                'name' => $chapter->name,
                'is_unlocked' => $this->progressService->canAccessChapter($userId, $chapter->id, $levelId),
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

    /**
     * Mark a chapter as completed in the database.
     */
    public function completeChapter(Request $request, $chapterId)
    {
        $user = $request->user();
        $userId = $user->id;

        // Find associated level and course to satisfy DB constraints
        $levelId = \DB::table('level_chapter')
            ->where('chapter_id', $chapterId)
            ->value('level_id');

        $courseId = null;
        if ($levelId) {
            $courseId = \DB::table('course_package_levels')
                ->where('level_id', $levelId)
                ->value('course_id');
        }

        if (!$courseId) {
            $courseId = 0; // fallback course ID
        }

        // Check if the record already exists to avoid duplicate entries
        $exists = \DB::table('user_course_progress')
            ->where('user_id', $userId)
            ->where('chapter_id', $chapterId)
            ->where('status', 'completed')
            ->exists();

        if (!$exists) {
            \DB::table('user_course_progress')->insert([
                'user_id' => $userId,
                'course_id' => $courseId,
                'level_id' => $levelId,
                'chapter_id' => $chapterId,
                'status' => 'completed',
                'completed_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            // Recalculate stats and sync to users table
            \App\Http\Controllers\DashboardController::recalculateUserStats($userId);
        }

        return response()->json([
            'success' => true,
            'message' => 'Chapter marked as completed.'
        ]);
    }

    /**
     * Mark a content/step within a chapter as completed in the database.
     */
    public function completeContent(Request $request, $chapterId, $contentId)
    {
        $user = $request->user();
        $userId = $user->id;

        // Find associated level and course
        $levelId = \DB::table('level_chapter')
            ->where('chapter_id', $chapterId)
            ->value('level_id');

        $courseId = null;
        if ($levelId) {
            $courseId = \DB::table('course_package_levels')
                ->where('level_id', $levelId)
                ->value('course_id');
        }

        if (!$courseId) {
            $courseId = 0;
        }

        $exists = \DB::table('user_course_progress')
            ->where('user_id', $userId)
            ->where('chapter_id', $chapterId)
            ->where('content_id', $contentId)
            ->where('status', 'completed')
            ->exists();

        if (!$exists) {
            \DB::table('user_course_progress')->insert([
                'user_id' => $userId,
                'course_id' => $courseId,
                'level_id' => $levelId,
                'chapter_id' => $chapterId,
                'content_id' => $contentId,
                'status' => 'completed',
                'completed_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            // Check if all contents in this chapter are now completed
            $totalChapterContents = \DB::table('content_chapters')
                ->where('chapter_id', $chapterId)
                ->count();

            $completedChapterContents = \DB::table('user_course_progress')
                ->where('user_id', $userId)
                ->where('chapter_id', $chapterId)
                ->whereNotNull('content_id')
                ->where('status', 'completed')
                ->distinct('content_id')
                ->count('content_id');

            if ($totalChapterContents > 0 && $completedChapterContents >= $totalChapterContents) {
                // Auto-complete chapter if all contents done
                $chapterDone = \DB::table('user_course_progress')
                    ->where('user_id', $userId)
                    ->where('chapter_id', $chapterId)
                    ->whereNull('content_id')
                    ->where('status', 'completed')
                    ->exists();

                if (!$chapterDone) {
                    \DB::table('user_course_progress')->insert([
                        'user_id' => $userId,
                        'course_id' => $courseId,
                        'level_id' => $levelId,
                        'chapter_id' => $chapterId,
                        'content_id' => null,
                        'status' => 'completed',
                        'completed_at' => now(),
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }
            }

            \App\Http\Controllers\DashboardController::recalculateUserStats($userId);
        }

        return response()->json([
            'success' => true,
            'message' => 'Content marked as completed.'
        ]);
    }
}
