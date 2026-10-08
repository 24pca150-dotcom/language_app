<?php

namespace App\Http\Controllers;

use App\Models\Assessment;
use App\Models\AssessmentQuestion;
use App\Models\QuestionOption;
use App\Models\UserAssessmentAttempt;
use Illuminate\Http\Request;

class AssessmentController extends Controller
{
    public function index(Request $request)
    {
        $query = Assessment::with(['level.course', 'chapter', 'questions.options']);

        if ($request->has('level_id')) {
            $query->where('level_id', $request->level_id);
        }
        if ($request->has('chapter_id')) {
            $query->where('chapter_id', $request->chapter_id);
        }

        $user = $request->user();
        if ($user && $user->role === 'student') {
            $query->where('is_active', true);
        }

        $assessments = $query->latest()->get();

        $attemptsMap = null;
        if ($user) {
            $attemptsMap = UserAssessmentAttempt::where('user_id', $user->id)
                ->orderBy('id', 'desc')
                ->get()
                ->groupBy('assessment_id');
        }

        $now = now();
        $assessments->transform(function ($item) use ($attemptsMap, $now) {
            if ($attemptsMap) {
                $attempts = $attemptsMap->get($item->id, collect());
                $latest = $attempts->first();
                $item->latest_attempt = $latest;
                $item->best_score = $attempts->max('score') ?? 0;
                $item->is_passed = $attempts->contains('passed', true);
                $item->total_attempts_count = $attempts->count();
            }

            // Scheduling status flags
            $isUpcoming = false;
            $isExpired = false;
            if ($item->scheduled_date && $now->lt($item->scheduled_date)) {
                $isUpcoming = true;
            }
            if ($item->due_date && $now->gt($item->due_date)) {
                $isExpired = true;
            }
            $item->is_upcoming = $isUpcoming;
            $item->is_expired = $isExpired;
            $item->is_available = !$isUpcoming && !$isExpired;

            return $item;
        });

        return response()->json($assessments);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'level_id' => 'nullable|exists:levels,id',
            'chapter_id' => 'nullable|exists:chapters,id',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'pass_percentage' => 'nullable|numeric|min:0|max:100',
            'is_mandatory' => 'boolean',
            'duration_minutes' => 'nullable|integer|min:0',
            'scheduled_date' => 'nullable|date',
            'open_hours' => 'nullable|numeric|min:0.1',
            'due_date' => 'nullable|date',
            'allow_restart' => 'boolean',
            'review_mode' => 'nullable|string|in:instantly,after_completion',
            'activity_type' => 'nullable|string|in:listen_audio,read_passage,watch_video,plain',
            'prelude_content' => 'nullable|string',
            'is_active' => 'boolean',
            'questions' => 'nullable|array',
            'questions.*.question_text' => 'required|string',
            'questions.*.question_type' => 'nullable|string',
            'questions.*.additional_data' => 'nullable|array',
            'questions.*.media_url' => 'nullable|string',
            'questions.*.sort_order' => 'nullable|integer',
            'questions.*.options' => 'nullable|array',
            'questions.*.options.*.option_text' => 'required|string|max:500',
            'questions.*.options.*.is_correct' => 'required|boolean',
            'questions.*.options.*.sort_order' => 'nullable|integer',
        ]);

        $createData = $request->only([
            'level_id',
            'chapter_id',
            'title',
            'description',
            'pass_percentage',
            'is_mandatory',
            'duration_minutes',
            'scheduled_date',
            'open_hours',
            'due_date',
            'allow_restart',
            'review_mode',
            'activity_type',
            'prelude_content',
            'is_active'
        ]);

        if (!empty($createData['scheduled_date']) && !empty($createData['open_hours']) && empty($createData['due_date'])) {
            $createData['due_date'] = \Carbon\Carbon::parse($createData['scheduled_date'])->addMinutes(round($createData['open_hours'] * 60));
        }

        $assessment = Assessment::create($createData);

        if (isset($validated['questions'])) {
            foreach ($validated['questions'] as $qIndex => $questionData) {
                $question = $assessment->questions()->create([
                    'question_text' => $questionData['question_text'],
                    'question_type' => $questionData['question_type'] ?? 'multiple_choice',
                    'additional_data' => $questionData['additional_data'] ?? null,
                    'media_url' => $questionData['media_url'] ?? null,
                    'sort_order' => $questionData['sort_order'] ?? $qIndex,
                ]);

                if (isset($questionData['options'])) {
                    foreach ($questionData['options'] as $oIndex => $optionData) {
                        $question->options()->create([
                            'option_text' => $optionData['option_text'],
                            'is_correct' => $optionData['is_correct'],
                            'sort_order' => $optionData['sort_order'] ?? $oIndex,
                        ]);
                    }
                }
            }
        }

        return response()->json($assessment->load(['level.course', 'chapter', 'questions.options']), 201);
    }

    public function show(Request $request, Assessment $assessment)
    {
        $data = $assessment->load(['level.course', 'chapter', 'questions.options'])->toArray();
        $user = $request->user();
        if ($user) {
            $data['user_attempt'] = UserAssessmentAttempt::where('user_id', $user->id)
                ->where('assessment_id', $assessment->id)
                ->latest()
                ->first();
        }
        return response()->json($data);
    }

    public function update(Request $request, Assessment $assessment)
    {
        $validated = $request->validate([
            'level_id' => 'nullable|exists:levels,id',
            'chapter_id' => 'nullable|exists:chapters,id',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'pass_percentage' => 'nullable|numeric|min:0|max:100',
            'is_mandatory' => 'boolean',
            'duration_minutes' => 'nullable|integer|min:0',
            'scheduled_date' => 'nullable|date',
            'open_hours' => 'nullable|numeric|min:0.1',
            'due_date' => 'nullable|date',
            'allow_restart' => 'boolean',
            'review_mode' => 'nullable|string|in:instantly,after_completion',
            'activity_type' => 'nullable|string|in:listen_audio,read_passage,watch_video,plain',
            'prelude_content' => 'nullable|string',
            'is_active' => 'boolean',
            'questions' => 'nullable|array',
            'questions.*.question_text' => 'required|string',
            'questions.*.question_type' => 'nullable|string',
            'questions.*.additional_data' => 'nullable|array',
            'questions.*.media_url' => 'nullable|string',
            'questions.*.sort_order' => 'nullable|integer',
            'questions.*.options' => 'nullable|array',
            'questions.*.options.*.option_text' => 'required|string|max:500',
            'questions.*.options.*.is_correct' => 'required|boolean',
            'questions.*.options.*.sort_order' => 'nullable|integer',
        ]);

        $updateData = $request->only([
            'level_id',
            'chapter_id',
            'title',
            'description',
            'pass_percentage',
            'is_mandatory',
            'duration_minutes',
            'scheduled_date',
            'open_hours',
            'due_date',
            'allow_restart',
            'review_mode',
            'activity_type',
            'prelude_content',
            'is_active'
        ]);

        if (!empty($updateData['scheduled_date']) && !empty($updateData['open_hours']) && empty($updateData['due_date'])) {
            $updateData['due_date'] = \Carbon\Carbon::parse($updateData['scheduled_date'])->addMinutes(round($updateData['open_hours'] * 60));
        }

        $assessment->update($updateData);

        if (isset($validated['questions'])) {
            $assessment->questions()->delete();
            foreach ($validated['questions'] as $qIndex => $questionData) {
                $question = $assessment->questions()->create([
                    'question_text' => $questionData['question_text'],
                    'question_type' => $questionData['question_type'] ?? 'multiple_choice',
                    'additional_data' => $questionData['additional_data'] ?? null,
                    'media_url' => $questionData['media_url'] ?? null,
                    'sort_order' => $questionData['sort_order'] ?? $qIndex,
                ]);

                if (isset($questionData['options'])) {
                    foreach ($questionData['options'] as $oIndex => $optionData) {
                        $question->options()->create([
                            'option_text' => $optionData['option_text'],
                            'is_correct' => $optionData['is_correct'],
                            'sort_order' => $optionData['sort_order'] ?? $oIndex,
                        ]);
                    }
                }
            }
        }

        return response()->json($assessment->load(['level.course', 'chapter', 'questions.options']));
    }

    public function destroy(Assessment $assessment)
    {
        $assessment->delete();
        return response()->noContent();
    }

    /**
     * Submit assessment attempt — calculates score and records pass/fail.
     */
    public function submitAttempt(Request $request, $assessmentId)
    {
        $assessment = Assessment::with('questions.options')->findOrFail($assessmentId);

        $validated = $request->validate([
            'user_id' => 'required|integer',
            'answers' => 'required|array',
            'answers.*.question_id' => 'required|integer',
            'answers.*.selected_option_id' => 'required|integer',
        ]);

        $totalQuestions = $assessment->questions->count();

        // Check scheduling window
        if ($assessment->scheduled_date && now()->lt($assessment->scheduled_date)) {
            return response()->json(['message' => 'This assessment has not started yet.'], 403);
        }
        if ($assessment->due_date && now()->gt($assessment->due_date)) {
            return response()->json(['message' => 'The exam window for this assessment has closed.'], 403);
        }

        // Check if student already attempted this assessment (Single attempt policy)
        $existingAttempt = UserAssessmentAttempt::where('user_id', $validated['user_id'])
            ->where('assessment_id', $assessment->id)
            ->first();

        if ($existingAttempt) {
            $computedCorrect = round(($existingAttempt->score / 100) * $totalQuestions);
            return response()->json([
                'attempt_id' => $existingAttempt->id,
                'score' => $existingAttempt->score,
                'passed' => (bool)$existingAttempt->passed,
                'total_questions' => $totalQuestions,
                'correct_answers' => $computedCorrect,
                'pass_percentage' => $assessment->pass_percentage,
                'already_completed' => true,
                'message' => 'Assessment already completed. Retakes are not allowed.'
            ], 200);
        }

        $correctAnswers = 0;

        foreach ($validated['answers'] as $answer) {
            $question = $assessment->questions->find($answer['question_id']);
            if ($question) {
                $correctOption = $question->options->where('is_correct', true)->first();
                if ($correctOption && $correctOption->id == $answer['selected_option_id']) {
                    $correctAnswers++;
                }
            }
        }

        $score = $totalQuestions > 0 ? round(($correctAnswers / $totalQuestions) * 100, 2) : 0;
        $passed = $score >= $assessment->pass_percentage;

        $attempt = UserAssessmentAttempt::create([
            'user_id' => $validated['user_id'],
            'assessment_id' => $assessment->id,
            'score' => $score,
            'passed' => $passed,
            'attempted_at' => now(),
        ]);

        // Update overall course progress if passed
        if ($passed) {
            \App\Models\UserCourseProgress::updateOrCreate(
                [
                    'user_id' => $validated['user_id'],
                    'level_id' => $assessment->level_id,
                    'chapter_id' => $assessment->chapter_id,
                ],
                [
                    'course_id' => $assessment->level?->course()->first()?->id ?? 0,
                    'status' => 'completed',
                    'score' => $score,
                    'completed_at' => now(),
                ]
            );
        }

        // Recalculate stats and sync to users table
        \App\Http\Controllers\DashboardController::recalculateUserStats($validated['user_id']);

        return response()->json([
            'attempt_id' => $attempt->id,
            'score' => $score,
            'passed' => $passed,
            'total_questions' => $totalQuestions,
            'correct_answers' => $correctAnswers,
            'pass_percentage' => $assessment->pass_percentage,
        ]);
    }

    /**
     * Get student attempts and marks for a specific assessment (Staff: Super Admin, Admin, Staff)
     */
    public function getStudentScores(Request $request, $assessmentId)
    {
        $assessment = Assessment::with(['level.course', 'chapter'])->findOrFail($assessmentId);

        $attempts = \DB::table('user_assessment_attempts')
            ->join('users', 'user_assessment_attempts.user_id', '=', 'users.id')
            ->where('user_assessment_attempts.assessment_id', $assessmentId)
            ->select(
                'user_assessment_attempts.id',
                'user_assessment_attempts.user_id',
                'users.name as student_name',
                'users.email as student_email',
                'users.username as student_username',
                'user_assessment_attempts.score',
                'user_assessment_attempts.passed',
                'user_assessment_attempts.attempted_at'
            )
            ->orderBy('user_assessment_attempts.attempted_at', 'desc')
            ->get();

        $totalAttempts = $attempts->count();
        $passedCount = $attempts->where('passed', true)->count();
        $avgScore = $totalAttempts > 0 ? round($attempts->avg('score'), 1) : 0;
        $maxScore = $totalAttempts > 0 ? round($attempts->max('score'), 1) : 0;

        return response()->json([
            'assessment' => [
                'id' => $assessment->id,
                'title' => $assessment->title,
                'pass_percentage' => $assessment->pass_percentage,
                'course_name' => $assessment->level?->course?->first()?->name ?? 'General',
                'chapter_title' => $assessment->chapter?->title ?? $assessment->chapter?->name ?? 'N/A',
            ],
            'stats' => [
                'total_attempts' => $totalAttempts,
                'passed_count' => $passedCount,
                'pass_rate' => $totalAttempts > 0 ? round(($passedCount / $totalAttempts) * 100, 1) : 0,
                'average_score' => $avgScore,
                'highest_score' => $maxScore,
            ],
            'attempts' => $attempts,
        ]);
    }
}
