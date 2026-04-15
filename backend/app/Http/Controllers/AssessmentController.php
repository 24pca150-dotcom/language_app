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
        $query = Assessment::with(['level.course', 'questions.options']);

        if ($request->has('level_id')) {
            $query->where('level_id', $request->level_id);
        }

        return response()->json($query->latest()->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'level_id' => 'required|exists:levels,id',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'pass_percentage' => 'nullable|numeric|min:0|max:100',
            'is_active' => 'boolean',
            'questions' => 'nullable|array',
            'questions.*.question_text' => 'required|string',
            'questions.*.sort_order' => 'nullable|integer',
            'questions.*.options' => 'required|array|min:2',
            'questions.*.options.*.option_text' => 'required|string|max:500',
            'questions.*.options.*.is_correct' => 'required|boolean',
            'questions.*.options.*.sort_order' => 'nullable|integer',
        ]);

        $assessment = Assessment::create([
            'level_id' => $validated['level_id'],
            'title' => $validated['title'],
            'description' => $validated['description'] ?? null,
            'pass_percentage' => $validated['pass_percentage'] ?? 70,
            'is_active' => $validated['is_active'] ?? true,
        ]);

        if (isset($validated['questions'])) {
            foreach ($validated['questions'] as $qIndex => $questionData) {
                $question = $assessment->questions()->create([
                    'question_text' => $questionData['question_text'],
                    'sort_order' => $questionData['sort_order'] ?? $qIndex,
                ]);

                foreach ($questionData['options'] as $oIndex => $optionData) {
                    $question->options()->create([
                        'option_text' => $optionData['option_text'],
                        'is_correct' => $optionData['is_correct'],
                        'sort_order' => $optionData['sort_order'] ?? $oIndex,
                    ]);
                }
            }
        }

        return response()->json($assessment->load(['level.course', 'questions.options']), 201);
    }

    public function show(Assessment $assessment)
    {
        return response()->json($assessment->load(['level.course', 'questions.options']));
    }

    public function update(Request $request, Assessment $assessment)
    {
        $validated = $request->validate([
            'level_id' => 'required|exists:levels,id',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'pass_percentage' => 'nullable|numeric|min:0|max:100',
            'is_active' => 'boolean',
            'questions' => 'nullable|array',
            'questions.*.id' => 'nullable|integer',
            'questions.*.question_text' => 'required|string',
            'questions.*.sort_order' => 'nullable|integer',
            'questions.*.options' => 'required|array|min:2',
            'questions.*.options.*.id' => 'nullable|integer',
            'questions.*.options.*.option_text' => 'required|string|max:500',
            'questions.*.options.*.is_correct' => 'required|boolean',
            'questions.*.options.*.sort_order' => 'nullable|integer',
        ]);

        $assessment->update([
            'level_id' => $validated['level_id'],
            'title' => $validated['title'],
            'description' => $validated['description'] ?? null,
            'pass_percentage' => $validated['pass_percentage'] ?? 70,
            'is_active' => $validated['is_active'] ?? true,
        ]);

        // Replace all questions and options
        if (isset($validated['questions'])) {
            // Delete existing questions (cascades to options)
            $assessment->questions()->delete();

            foreach ($validated['questions'] as $qIndex => $questionData) {
                $question = $assessment->questions()->create([
                    'question_text' => $questionData['question_text'],
                    'sort_order' => $questionData['sort_order'] ?? $qIndex,
                ]);

                foreach ($questionData['options'] as $oIndex => $optionData) {
                    $question->options()->create([
                        'option_text' => $optionData['option_text'],
                        'is_correct' => $optionData['is_correct'],
                        'sort_order' => $optionData['sort_order'] ?? $oIndex,
                    ]);
                }
            }
        }

        return response()->json($assessment->load(['level.course', 'questions.options']));
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

        return response()->json([
            'attempt_id' => $attempt->id,
            'score' => $score,
            'passed' => $passed,
            'total_questions' => $totalQuestions,
            'correct_answers' => $correctAnswers,
            'pass_percentage' => $assessment->pass_percentage,
        ]);
    }
}
