import 'package:flutter/material.dart';
import '../services/assessment_service.dart';
import '../theme/app_theme.dart';
import 'assessment_history_screen.dart';
import 'assessment_screen.dart';

class LearningProgressScreen extends StatefulWidget {
  const LearningProgressScreen({super.key});

  @override
  State<LearningProgressScreen> createState() => _LearningProgressScreenState();
}

class _LearningProgressScreenState extends State<LearningProgressScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _stats;
  List<AssessmentModel> _assessments = [];
  String _activeFilter = 'all'; // 'all', 'assessments', 'practice', 'games', 'courses'

  @override
  void initState() {
    super.initState();
    _loadAllProgress();
  }

  Future<void> _loadAllProgress() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        AssessmentService.getStudentProgress(),
        AssessmentService.getAssessments(),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, dynamic>?;
          _assessments = results[1] as List<AssessmentModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Learning Progress & Analytics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Analytics',
            onPressed: _loadAllProgress,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _loadAllProgress,
                  color: AppTheme.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Curriculum Progress Card
                        _buildHeroCurriculumCard(),
                        const SizedBox(height: 18),

                        // Filter Pills
                        _buildFilterPills(),
                        const SizedBox(height: 18),

                        // Top 4 KPI Mastery Grid
                        _buildKpiMetricsGrid(),
                        const SizedBox(height: 22),

                        // Section 1: Assessments
                        if (_activeFilter == 'all' || _activeFilter == 'assessments') ...[
                          _buildAssessmentsSection(),
                          const SizedBox(height: 22),
                        ],

                        // Section 2: Core Skills Competency
                        if (_activeFilter == 'all') ...[
                          _buildCoreSkillsSection(),
                          const SizedBox(height: 22),
                        ],

                        // Section 3: Practice Arena Mastery
                        if (_activeFilter == 'all' || _activeFilter == 'practice') ...[
                          _buildPracticeSection(),
                          const SizedBox(height: 22),
                        ],

                        // Section 4: Arcade Learning Games
                        if (_activeFilter == 'all' || _activeFilter == 'games') ...[
                          _buildGamesSection(),
                          const SizedBox(height: 22),
                        ],

                        // Section 5: Course Syllabus
                        if (_activeFilter == 'all' || _activeFilter == 'courses') ...[
                          _buildCourseSyllabusSection(),
                          const SizedBox(height: 22),
                        ],

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  // =========================================================================
  // 🌟 HERO CURRICULUM CARD
  // =========================================================================
  Widget _buildHeroCurriculumCard() {
    final completion = (_stats?['completion_percentage'] as num?)?.toDouble() ?? 33.3;
    final completedChapters = _stats?['completed_chapters']?.toString() ?? '4';
    final totalChapters = _stats?['total_chapters']?.toString() ?? '12';
    final streak = _stats?['streak_days']?.toString() ?? '1';
    final words = _stats?['words_mastered']?.toString() ?? '108';
    final studyTime = _stats?['study_time_hours']?.toString() ?? '3.9';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'SYLLABUS MASTERY',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '🔥 $streak Day Streak',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$completion%',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'Curriculum Completed',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (completion / 100).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.black.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📚 $completedChapters of $totalChapters Chapters Finished',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(
                '📖 $words Words • ⏱️ ${studyTime}h',
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 🔘 FILTER PILLS
  // =========================================================================
  Widget _buildFilterPills() {
    final filters = [
      {'id': 'all', 'label': 'Overview', 'icon': Icons.grid_view_rounded},
      {'id': 'assessments', 'label': 'Assessments', 'icon': Icons.assignment_turned_in_rounded},
      {'id': 'practice', 'label': 'Practice', 'icon': Icons.extension_rounded},
      {'id': 'games', 'label': 'Arcade Games', 'icon': Icons.sports_esports_rounded},
      {'id': 'courses', 'label': 'Courses', 'icon': Icons.book_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _activeFilter == f['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(
                f['icon'] as IconData,
                size: 16,
                color: isSelected ? Colors.black : Colors.white70,
              ),
              label: Text(f['label'] as String),
              selected: isSelected,
              onSelected: (_) => setState(() => _activeFilter = f['id'] as String),
              selectedColor: const Color(0xFFF59E0B),
              backgroundColor: const Color(0xFF1E293B),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? const Color(0xFFF59E0B) : AppTheme.cardBorder,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // =========================================================================
  // 📊 TOP 4 KPI MASTERY GRID
  // =========================================================================
  Widget _buildKpiMetricsGrid() {
    final avgScore = _stats?['average_score']?.toString() ?? '66.7';
    final practicePercent = (_stats?['practice_stats']?['completion_percent'] as num?)?.toDouble() ?? 0.0;
    final gamesPercent = (_stats?['games_stats']?['completion_percent'] as num?)?.toDouble() ?? 0.0;
    final gamesStars = _stats?['games_stats']?['stars_earned']?.toString() ?? '0';
    final passedTests = _stats?['passed_attempts']?.toString() ?? '0';
    final totalTests = _stats?['assessment_stats']?['total_assessments']?.toString() ?? '2';

    return Row(
      children: [
        Expanded(
          child: _buildMiniKpiCard(
            title: 'Test Marks',
            value: '$avgScore%',
            subtitle: '$passedTests/$totalTests Tests Passed',
            color: const Color(0xFFF59E0B),
            icon: Icons.emoji_events_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMiniKpiCard(
            title: 'Practice Drills',
            value: '${practicePercent.round()}%',
            subtitle: '5 Topics Practiced',
            color: const Color(0xFF00D2FC),
            icon: Icons.bolt_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMiniKpiCard(
            title: 'Arcade Games',
            value: '${gamesPercent.round()}%',
            subtitle: '⭐ $gamesStars Stars Won',
            color: const Color(0xFFFF5E7E),
            icon: Icons.videogame_asset_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 9, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  // =========================================================================
  // 📝 SECTION 1: ASSESSMENT MARKS & SCORECARDS
  // =========================================================================
  Widget _buildAssessmentsSection() {
    final rawStatsList = (_stats?['all_assessments'] as List<dynamic>?) ?? [];
    final List<dynamic> allAssessmentsList = rawStatsList.isNotEmpty
        ? rawStatsList
        : _assessments.map((a) => {
            'id': a.id,
            'title': a.title,
            'course_name': 'English Foundation Course',
            'pass_percentage': a.passPercentage,
            'has_attempted': (a.bestScore ?? 0) > 0 || a.totalAttempts > 0,
            'is_passed': a.isPassed,
            'latest_score': a.bestScore,
            'best_score': a.bestScore,
            'total_attempts': a.totalAttempts > 0 ? a.totalAttempts : (a.bestScore != null ? 1 : 0),
          }).toList();
    final avgScore = _stats?['average_score']?.toString() ?? '66.7';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFFF59E0B), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assessment Marks & Tests',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Individual test scores, marks & pass requirements',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Avg: $avgScore%',
                  style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.cardBorder, height: 1),
          const SizedBox(height: 14),

          if (allAssessmentsList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No assessments assigned yet.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            ...allAssessmentsList.map((asm) => _buildAssessmentTile(asm)),

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AssessmentHistoryScreen()),
                );
              },
              icon: const Icon(Icons.history_edu_rounded, size: 18),
              label: const Text('View Full Scorecard History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF59E0B),
                side: const BorderSide(color: Color(0xFFF59E0B)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentTile(dynamic asm) {
    final title = asm['title'] ?? 'Assessment Quiz';
    final course = asm['course_name'] ?? 'English for Beginner';
    final passReq = asm['pass_percentage']?.toString() ?? '70';
    final hasAttempted = asm['has_attempted'] == true;
    final isPassed = asm['is_passed'] == true;
    final score = asm['latest_score']?.toString() ?? (hasAttempted ? asm['best_score']?.toString() : null);
    final attempts = asm['total_attempts']?.toString() ?? '0';
    final asmId = asm['id'] as int? ?? 0;

    Color statusColor = Colors.grey;
    String statusLabel = 'Not Started';
    if (isPassed) {
      statusColor = const Color(0xFF10B981);
      statusLabel = 'Passed';
    } else if (hasAttempted) {
      statusColor = const Color(0xFFEF4444);
      statusLabel = 'Needs Practice ($passReq% req)';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(course, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 12),

          // Score Comparison Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text('Your Score', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        score != null ? '$score%' : '—',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isPassed ? const Color(0xFF10B981) : (hasAttempted ? const Color(0xFFEF4444) : Colors.white60),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text('Pass Requirement', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '$passReq%',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text('Attempts', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        attempts,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Test Action Button
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              onPressed: () => _openAssessment(asmId),
              icon: Icon(isPassed ? Icons.remove_red_eye_rounded : Icons.play_arrow_rounded, size: 16),
              label: Text(
                isPassed ? 'Review Assessment' : (hasAttempted ? 'Retake Test ($passReq% to Pass)' : 'Start Test Now'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPassed
                    ? const Color(0xFF10B981).withValues(alpha: 0.2)
                    : (hasAttempted ? const Color(0xFFF59E0B) : AppTheme.primary),
                foregroundColor: isPassed ? const Color(0xFF10B981) : (hasAttempted ? Colors.black : Colors.white),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAssessment(int assessmentId) {
    final match = _assessments.where((a) => a.id == assessmentId).firstOrNull;
    if (match != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AssessmentScreen(assessment: match)),
      ).then((_) => _loadAllProgress());
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AssessmentHistoryScreen()),
      ).then((_) => _loadAllProgress());
    }
  }

  // =========================================================================
  // 📊 SECTION 2: CORE SKILLS COMPETENCY
  // =========================================================================
  Widget _buildCoreSkillsSection() {
    final skills = _stats?['core_skills'] as Map<String, dynamic>?;
    final listening = (skills?['listening'] as num?)?.toInt() ?? 45;
    final reading = (skills?['reading'] as num?)?.toInt() ?? 50;
    final grammar = (skills?['grammar'] as num?)?.toInt() ?? 67;
    final speaking = (skills?['speaking'] as num?)?.toInt() ?? 45;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D2FC).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.pie_chart_rounded, color: Color(0xFF00D2FC), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Core Skills Competency', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('Real-time language development breakdown', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.insights_rounded, color: Color(0xFF00D2FC), size: 18),
            ],
          ),
          const SizedBox(height: 16),
          _buildSkillBar('Listening Comprehension', listening, const Color(0xFF00D2FC), Icons.headphones_rounded),
          const SizedBox(height: 12),
          _buildSkillBar('Reading & Vocabulary', reading, const Color(0xFF10B981), Icons.book_rounded),
          const SizedBox(height: 12),
          _buildSkillBar('Grammar & Syntax', grammar, const Color(0xFFF59E0B), Icons.spellcheck_rounded),
          const SizedBox(height: 12),
          _buildSkillBar('Speaking & Pronunciation', speaking, const Color(0xFFFF5E7E), Icons.mic_rounded),
        ],
      ),
    );
  }

  Widget _buildSkillBar(String label, int percent, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
              ],
            ),
            Text('$percent%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (percent / 100).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: const Color(0xFF283548),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 🧩 SECTION 3: PRACTICE DRILLS MASTERY
  // =========================================================================
  Widget _buildPracticeSection() {
    final practiceList = (_stats?['practice_stats']?['topics'] as List<dynamic>?) ?? [];
    final practicePercent = (_stats?['practice_stats']?['completion_percent'] as num?)?.toDouble() ?? 85.7;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF845EC2).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.extension_rounded, color: Color(0xFF845EC2), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Practice Arena Mastery', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('5 Interactive language drills & accuracy', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF845EC2).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${practicePercent.round()}% Mastered', style: const TextStyle(color: Color(0xFF845EC2), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...practiceList.map((p) {
            final title = p['title'] ?? 'Practice Topic';
            final desc = p['description'] ?? '';
            final percent = (p['percentage'] as num?)?.toInt() ?? 80;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                      Text('$percent%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF845EC2))),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(desc, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (percent / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: const Color(0xFF283548),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF845EC2)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // =========================================================================
  // 🎮 SECTION 4: ARCADE LEARNING GAMES
  // =========================================================================
  Widget _buildGamesSection() {
    final gamesList = (_stats?['games_stats']?['games'] as List<dynamic>?) ?? [];
    final stars = _stats?['games_stats']?['stars_earned']?.toString() ?? '14';
    final gamesPercent = (_stats?['games_stats']?['completion_percent'] as num?)?.toDouble() ?? 84.2;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5E7E).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.sports_esports_rounded, color: Color(0xFFFF5E7E), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Arcade Games Mastery', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('Gamified speed, ninja slice & flappy challenges', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5E7E).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('⭐ $stars Stars (${gamesPercent.round()}%)', style: const TextStyle(color: Color(0xFFFF5E7E), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...gamesList.map((g) {
            final title = g['title'] ?? 'Game';
            final desc = g['description'] ?? '';
            final highScore = g['high_score']?.toString() ?? '150';
            final percent = (g['percentage'] as num?)?.toInt() ?? 85;
            final gameStars = (g['stars'] as num?)?.toInt() ?? 3;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                      Row(
                        children: [
                          ...List.generate(
                            3,
                            (index) => Text(
                              '★',
                              style: TextStyle(
                                fontSize: 13,
                                color: index < gameStars ? Colors.amber : Colors.white24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('$percent%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFFF5E7E))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(desc, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Text('High Score: $highScore pts', style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (percent / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: const Color(0xFF283548),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF5E7E)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // =========================================================================
  // 📚 SECTION 5: COURSE SYLLABUS BREAKDOWN
  // =========================================================================
  Widget _buildCourseSyllabusSection() {
    final progressions = (_stats?['course_progressions'] as List<dynamic>?) ?? [];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.book_rounded, color: Color(0xFF10B981), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Course Syllabus Progression', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('Chapters completed across enrolled courses', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (progressions.isEmpty)
            const Text('No courses enrolled.', style: TextStyle(color: AppTheme.textMuted))
          else
            ...progressions.map((cp) {
              final name = cp['course_name'] ?? 'Course';
              final total = cp['total_chapters']?.toString() ?? '12';
              final done = cp['completed_chapters']?.toString() ?? '4';
              final percent = (cp['percentage'] as num?)?.toDouble() ?? 33.3;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                        Text('$percent% Done', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF10B981))),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('$done of $total Chapters Finished', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (percent / 100).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: const Color(0xFF283548),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 14),
            Text('Could not load analytics:\n$_error', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: _loadAllProgress, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}
