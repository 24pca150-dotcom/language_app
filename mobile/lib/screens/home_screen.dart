import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/assessment_service.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import '../theme/app_theme.dart';
import 'assessment_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onTabChange;

  const HomeScreen({super.key, required this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _user;
  List<MobileCourseItem> _courses = [];
  List<MobileLevel> _levels = [];
  AssessmentModel? _activeAssessment;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    final user = await AuthService.getUserProfile();
    var courses = <MobileCourseItem>[];
    var levels = <MobileLevel>[];
    AssessmentModel? activeAssessment;
    String? loadError;

    try {
      courses = await CourseService.getCourses();
      if (courses.isNotEmpty) {
        levels = await CourseService.getCourseStructure(
          courseId: courses.first.id,
        );
      }
      final assessments = await AssessmentService.getAssessments();
      final availableAssessments = assessments
          .where((assessment) => assessment.questions.isNotEmpty)
          .toList();
      activeAssessment = availableAssessments.isNotEmpty
          ? availableAssessments.first
          : null;
    } catch (error) {
      loadError = error.toString();
    }

    if (mounted) {
      setState(() {
        _user = user;
        _courses = courses;
        _levels = levels;
        _activeAssessment = activeAssessment;
        _loadError = loadError;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    final user = _user!;
    final activeLevel = _levels.isNotEmpty ? _levels.first : null;
    final activeChapter =
        (activeLevel != null && activeLevel.chapters.isNotEmpty)
        ? activeLevel.chapters.first
        : null;
    final progress = activeChapter?.progress ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppTheme.navBarGreen,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: AppTheme.navBarGreenBorder, width: 1.2),
        ),
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: AppTheme.navBarGreenDark,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Welcome, ${user.name} 👋',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF14361F),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => widget.onTabChange(3),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: AppTheme.navBarGreen,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navBarGreenDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gamification Stats Row (Streak, XP, Coins)
              Row(
                children: [
                  _buildStat(
                    '🔥 ${user.streakDays} Days',
                    'Streak',
                    const Color(0xFFFFF1F2),
                    const Color(0xFFE11D48),
                  ),
                  const SizedBox(width: 10),
                  _buildStat(
                    '⚡ ${user.xp}',
                    'Total XP',
                    const Color(0xFFEFF6FF),
                    const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 10),
                  _buildStat(
                    '🪙 ${user.coins}',
                    'Coins',
                    const Color(0xFFFFFBEB),
                    const Color(0xFFD97706),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_loadError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Some learning data could not sync. Pull down to retry.\n$_loadError',
                    style: const TextStyle(
                      color: AppTheme.danger,
                      fontSize: 12,
                    ),
                  ),
                ),

              if (_courses.isNotEmpty) ...[
                // Compact Continue Learning Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _courses.first.code,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(progress * 100).round()}% Completed',
                            style: const TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _courses.first.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  activeChapter != null
                                      ? '${activeLevel!.name}: ${activeChapter.name}'
                                      : 'No lessons available yet',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () =>
                                widget.onTabChange(1), // Go to Learn
                            icon: const Icon(
                              Icons.play_arrow_rounded,
                              size: 16,
                            ),
                            label: const Text(
                              'Continue',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF34D399),
                          ),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_courses.isEmpty && _loadError == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No active courses are assigned to your account yet.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              const SizedBox(height: 14),

              // 📝 ACTIVE ASSESSMENT BANNER CARD
              if (_activeAssessment != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.assignment_turned_in_rounded,
                          color: AppTheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'QUIZ',
                                    style: TextStyle(
                                      color: Color(0xFFD97706),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${_activeAssessment!.totalQuestions} Qs • ${_activeAssessment!.timeLimitMinutes}m',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _activeAssessment!.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AssessmentScreen(
                                assessment: _activeAssessment!,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Take Test',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
              const SizedBox(height: 24),

              // Quick Activity Hub
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Learning Zones',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.onTabChange(1),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'View All',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildZoneCard(
                      title: 'Curriculum',
                      subtitle:
                          '${_courses.isNotEmpty ? _courses.first.levelsCount : _levels.length} Levels & Chapters',
                      icon: Icons.menu_book_rounded,
                      color: const Color(0xFF6366F1),
                      onTap: () => widget.onTabChange(1),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildZoneCard(
                      title: 'Games',
                      subtitle: 'Ninja, Racer & Quizzes',
                      icon: Icons.sports_esports_rounded,
                      color: const Color(0xFF10B981),
                      onTap: () => widget.onTabChange(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(
    String title,
    String label,
    Color bgColor,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: textColor.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
