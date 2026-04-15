<?php

namespace App\Http\Controllers;

use App\Models\Course;
use App\Models\Level;
use App\Models\UserAssessmentAttempt;
use Illuminate\Http\Request;

class LearningProgressController extends Controller
{
    /**
     * Get user progress for all levels in a course (strict mode).
     * Level 1 is always unlocked. Subsequent levels unlock only if
     * the previous level's assessment has been passed.
     */
    public function getUserProgress($userId, $courseId)
    {
        $course = Course::with(['levels' => function ($q) {
            $q->orderBy('sort_order');
        }, 'levels.assessment'])->findOrFail($courseId);

        $levels = [];
        $previousPassed = true; // First level is always unlocked

        foreach ($course->levels as $level) {
            $assessment = $level->assessment;
            $assessmentPassed = false;
            $bestScore = null;

            if ($assessment) {
                $bestAttempt = UserAssessmentAttempt::where('user_id', $userId)
                    ->where('assessment_id', $assessment->id)
                    ->where('passed', true)
                    ->orderBy('score', 'desc')
                    ->first();

                if ($bestAttempt) {
                    $assessmentPassed = true;
                    $bestScore = $bestAttempt->score;
                }
            }

            $levels[] = [
                'level_id' => $level->id,
                'name' => $level->name,
                'code' => $level->code,
                'sort_order' => $level->sort_order,
                'is_unlocked' => $previousPassed,
                'assessment_passed' => $assessmentPassed,
                'score' => $bestScore,
                'has_assessment' => $assessment !== null,
            ];

            // For next level, check if current level's assessment is passed
            $previousPassed = $assessmentPassed;
        }

        return response()->json([
            'course' => [
                'id' => $course->id,
                'name' => $course->name,
                'code' => $course->code,
            ],
            'levels' => $levels,
        ]);
    }

    /**
     * Check if a specific level is accessible to a user.
     */
    public function getLevelAccess($userId, $levelId)
    {
        $level = Level::with('course')->findOrFail($levelId);

        // Get the previous level in sort order
        $previousLevel = Level::where('course_id', $level->course_id)
            ->where('sort_order', '<', $level->sort_order)
            ->orderBy('sort_order', 'desc')
            ->first();

        // First level is always unlocked
        if (!$previousLevel) {
            return response()->json(['is_unlocked' => true, 'reason' => 'First level']);
        }

        // Check if previous level's assessment was passed
        $previousAssessment = $previousLevel->assessment;

        if (!$previousAssessment) {
            return response()->json(['is_unlocked' => true, 'reason' => 'No assessment on previous level']);
        }

        $passed = UserAssessmentAttempt::where('user_id', $userId)
            ->where('assessment_id', $previousAssessment->id)
            ->where('passed', true)
            ->exists();

        return response()->json([
            'is_unlocked' => $passed,
            'reason' => $passed
                ? 'Previous level assessment passed'
                : 'Must pass previous level assessment first',
        ]);
    }
}
