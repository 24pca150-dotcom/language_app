import 'package:flutter/material.dart';

import '../services/assessment_service.dart';
import '../theme/app_theme.dart';
import 'assessment_screen.dart';

class AssessmentHistoryScreen extends StatefulWidget {
  const AssessmentHistoryScreen({super.key});

  @override
  State<AssessmentHistoryScreen> createState() =>
      _AssessmentHistoryScreenState();
}

class _AssessmentHistoryScreenState extends State<AssessmentHistoryScreen> {
  List<AssessmentModel> _assessments = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final list = await AssessmentService.getAssessments();
      if (mounted) {
        setState(() {
          _assessments = list
              .where((assessment) => assessment.questions.isNotEmpty)
              .toList();
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadError = error.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assessment History & Progress')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadAssessments,
              color: AppTheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_loadError != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.cloud_off_rounded,
                                color: AppTheme.textMuted,
                                size: 36,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Could not load assessments.\n$_loadError',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              TextButton(
                                onPressed: _loadAssessments,
                                child: const Text('Try again'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      // Summary Performance Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'OVERALL PERFORMANCE',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Icon(
                                  Icons.workspace_premium_rounded,
                                  color: Colors.amber,
                                  size: 24,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${_assessments.where((assessment) => assessment.totalAttempts > 0).length} of ${_assessments.length} assessments attempted',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _buildMiniStat(_averageScore, 'Avg Score'),
                                const SizedBox(width: 12),
                                _buildMiniStat('$_passedAssessments', 'Passed'),
                                const SizedBox(width: 12),
                                _buildMiniStat('$_totalAttempts', 'Attempts'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Assigned & Attempted Tests',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (_assessments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No active assessments are available yet.',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                        )
                      else
                        ..._assessments.map((a) => _buildAssessmentTile(a)),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  String get _averageScore {
    final attempted = _assessments
        .where(
          (assessment) =>
              assessment.totalAttempts > 0 && assessment.bestScore != null,
        )
        .toList();
    if (attempted.isEmpty) return '—';
    final average =
        attempted
            .map((assessment) => assessment.bestScore!)
            .reduce((sum, score) => sum + score) /
        attempted.length;
    return '${average.round()}%';
  }

  int get _passedAssessments =>
      _assessments.where((assessment) => assessment.isPassed).length;

  int get _totalAttempts =>
      _assessments.fold(0, (sum, assessment) => sum + assessment.totalAttempts);

  Widget _buildMiniStat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentTile(AssessmentModel a) {
    final bool passed =
        a.isPassed || (a.bestScore != null && a.bestScore! >= a.passPercentage);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AssessmentScreen(assessment: a),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (passed ? AppTheme.secondary : AppTheme.primary)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        passed
                            ? Icons.check_circle_rounded
                            : Icons.assignment_rounded,
                        color: passed ? AppTheme.secondary : AppTheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            a.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${a.totalQuestions} Questions • ${a.timeLimitMinutes} Mins',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    if (a.bestScore != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (passed ? AppTheme.secondary : AppTheme.danger)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Score: ${a.bestScore!.toInt()}%',
                          style: TextStyle(
                            color: passed
                                ? AppTheme.secondary
                                : AppTheme.danger,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      )
                    else
                      const Text(
                        'Take Test →',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
