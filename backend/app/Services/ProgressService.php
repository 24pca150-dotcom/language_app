<?php

namespace App\Services;

use App\Models\Assessment;
use App\Models\Chapter;
use App\Models\UserAssessmentAttempt;
use App\Models\UserCourseProgress;
use App\Models\Package;

class ProgressService
{
    /**
     * Check if a user can access a specific chapter within a level.
     */
    public function canAccessChapter($userId, $chapterId, $levelId = null)
    {
        $chapter = Chapter::find($chapterId);
        if (!$chapter) return false;

        $learningMode = $this->getUserLearningMode($userId);

        if ($learningMode === 'FREE_STYLE') {
            return true;
        }

        // Strict Mode Logic:
        // Check if previous chapter in this level is completed
        if ($levelId) {
            $currentSortOrder = \DB::table('level_chapter')
                ->where('level_id', $levelId)
                ->where('chapter_id', $chapterId)
                ->value('sort_order') ?? 0;

            $previousChapterId = \DB::table('level_chapter')
                ->where('level_id', $levelId)
                ->where('sort_order', '<', $currentSortOrder)
                ->orderBy('sort_order', 'desc')
                ->value('chapter_id');

            if ($previousChapterId) {
                if (!$this->isChapterCompleted($userId, $previousChapterId)) {
                    return false;
                }
            }
        }

        return true;
    }

    /**
     * Check if a chapter is completed by user.
     */
    public function isChapterCompleted($userId, $chapterId)
    {
        // A chapter is completed if all mandatory assessments for it are passed
        $mandatoryAssessments = Assessment::where('chapter_id', $chapterId)
            ->where('is_mandatory', true)
            ->get();

        foreach ($mandatoryAssessments as $assessment) {
            $passed = UserAssessmentAttempt::where('user_id', $userId)
                ->where('assessment_id', $assessment->id)
                ->where('passed', true)
                ->exists();
            if (!$passed) return false;
        }

        return true;
    }

    /**
     * Placeholder for getting user learning mode.
     * In a full implementation, this would join users -> subscriptions -> packages -> learning_modes.
     */
    public function getUserLearningMode($userId)
    {
        // Stub: Default to STRICT_MODE if unknown
        return 'STRICT_MODE';
    }
}
