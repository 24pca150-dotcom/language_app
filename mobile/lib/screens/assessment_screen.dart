import 'dart:async';

import 'package:flutter/material.dart';

import '../services/assessment_service.dart';
import '../theme/app_theme.dart';

class AssessmentScreen extends StatefulWidget {
  final AssessmentModel assessment;

  const AssessmentScreen({super.key, required this.assessment});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedOptionIndices =
      {}; // questionIndex -> optionIndex
  int _secondsLeft = 600; // 10 minutes
  Timer? _timer;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.assessment.timeLimitMinutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft > 0) {
        if (mounted) setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
        _submitTest();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _submitTest() async {
    _timer?.cancel();
    setState(() => _isSubmitting = true);

    int correct = 0;
    final questions = widget.assessment.questions;

    for (int i = 0; i < questions.length; i++) {
      final selectedOptIdx = _selectedOptionIndices[i];
      if (selectedOptIdx != null &&
          selectedOptIdx < questions[i].options.length) {
        if (questions[i].options[selectedOptIdx].isCorrect) {
          correct++;
        }
      }
    }

    final total = questions.isNotEmpty ? questions.length : 1;
    final score = ((correct / total) * 100).round();
    final isPassed = score >= widget.assessment.passPercentage;

    try {
      await AssessmentService.submitAssessment(
        assessmentId: widget.assessment.id,
        correctAnswers: correct,
        totalQuestions: total,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save assessment result: $error')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(
              isPassed ? Icons.verified_rounded : Icons.info_rounded,
              color: isPassed ? AppTheme.secondary : AppTheme.danger,
            ),
            const SizedBox(width: 10),
            Text(
              isPassed ? 'Test Passed! 🎉' : 'Needs Practice',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: (isPassed ? AppTheme.secondary : AppTheme.danger)
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$score%',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isPassed ? AppTheme.secondary : AppTheme.danger,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'You scored $correct out of $total questions correct!',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isPassed
                  ? 'Great job! Score recorded and +$score XP awarded to your profile.'
                  : 'Passing score is ${widget.assessment.passPercentage}%. You can retry anytime!',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // back to previous screen
              },
              child: const Text('Return to Dashboard'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.assessment.questions;
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assessment')),
        body: const Center(
          child: Text('No questions available in this assessment.'),
        ),
      );
    }

    final currentQ = questions[_currentQuestionIndex];
    final selectedIdx = _selectedOptionIndices[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.assessment.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  color: Color(0xFFD97706),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(_secondsLeft),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              minHeight: 5,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question Counter & Marks
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'QUESTION ${_currentQuestionIndex + 1} OF ${questions.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '1 Mark',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Question Text Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        currentQ.questionText,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Select the correct answer:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Options List
                    ...List.generate(currentQ.options.length, (optIdx) {
                      final opt = currentQ.options[optIdx];
                      final isSelected = selectedIdx == optIdx;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedOptionIndices[_currentQuestionIndex] =
                                  optIdx;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primary.withValues(alpha: 0.08)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.cardBorder,
                                width: isSelected ? 2.0 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? AppTheme.primary
                                        : const Color(0xFFF1F5F9),
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(
                                        65 + optIdx,
                                      ), // A, B, C, D
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : AppTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    opt.text,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppTheme.primary,
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Bottom Navigation & Submit Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.cardBorder)),
              ),
              child: Row(
                children: [
                  if (_currentQuestionIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            setState(() => _currentQuestionIndex--),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentQuestionIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              if (_currentQuestionIndex <
                                  questions.length - 1) {
                                setState(() => _currentQuestionIndex++);
                              } else {
                                _submitTest();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _currentQuestionIndex == questions.length - 1
                            ? AppTheme.secondary
                            : AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _currentQuestionIndex == questions.length - 1
                            ? 'Submit Assessment'
                            : 'Next Question →',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
