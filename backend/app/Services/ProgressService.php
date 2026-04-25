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
     * Check if a user can access a specific chapter.
     */
    public function canAccessChapter($userId, $chapterId)
    {
        $chapter = Chapter::with('level.course')->find($chapterId);
        if (!$chapter) return false;

        // Find user's package and learning mode
        // For now, we assume user_id is linked to a package somehow.
        // In a real app, we'd check enrollments.
        // Let's assume a simple lookup for this demo.
        $learningMode = $this->getUserLearningMode($userId);

        if ($learningMode === 'FREE_STYLE') {
            return true;
        }

        // Strict Mode Logic:
        // Check if previous chapter is completed
        $previousChapter = Chapter::where('level_id', $chapter->level_id)
            ->where('sort_order', '<', $chapter->sort_order)
            ->orderBy('sort_order', 'desc')
            ->first();

        if ($previousChapter) {
            if (!$this->isChapterCompleted($userId, $previousChapter->id)) {
                return false;
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
