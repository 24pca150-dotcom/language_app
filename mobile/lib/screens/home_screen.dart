import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/assessment_service.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import '../services/live_class_service.dart';
import '../theme/app_theme.dart';
import 'assessment_history_screen.dart';
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
  List<AssessmentModel> _assessments = [];
  List<LiveClassModel> _liveClasses = [];
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
    String? loadError;

    try {
      courses = await CourseService.getCourses();
      if (courses.isNotEmpty) {
        levels = await CourseService.getCourseStructure(
          courseId: courses.first.id,
        );
      }
    } catch (error) {
      loadError = error.toString();
    }

    var assessments = <AssessmentModel>[];
    try {
      assessments = await AssessmentService.getAssessments();
    } catch (e) {
// Assessment load error suppressed
    }

    var liveClasses = <LiveClassModel>[];
    try {
      liveClasses = await LiveClassService.getUpcomingLiveClasses();
    } catch (_) {
      // Live classes suppressed
    }

    if (mounted) {
      setState(() {
        _user = user;
        _courses = courses;
        _levels = levels;
        _assessments = assessments;
        _liveClasses = liveClasses;
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
    MobileChapter? activeChapter;
    MobileLevel? activeLevel;
    for (var lvl in _levels) {
      for (var ch in lvl.chapters) {
        if (ch.progress < 1.0) {
          activeChapter = ch;
          activeLevel = lvl;
          break;
        }
      }
      if (activeChapter != null) break;
    }
    if (activeChapter == null && _levels.isNotEmpty && _levels.first.chapters.isNotEmpty) {
      activeLevel = _levels.first;
      activeChapter = _levels.first.chapters.first;
    }

    final double progress = (_courses.isNotEmpty && _courses.first.progress > 0)
        ? _courses.first.progress
        : (activeChapter?.progress ?? 0.0);

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
                  color: Colors.white,
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
                    const Color(0xFF161F38),
                    const Color(0xFFFB7185),
                  ),
                  const SizedBox(width: 10),
                  _buildStat(
                    '⚡ ${user.xp}',
                    'Total XP',
                    const Color(0xFF161F38),
                    const Color(0xFF38BDF8),
                  ),
                  const SizedBox(width: 10),
                  _buildStat(
                    '🪙 ${user.coins}',
                    'Coins',
                    const Color(0xFF161F38),
                    const Color(0xFFFBBF24),
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

              // 🎥 UPCOMING LIVE CLASSES SECTION (Live & Scheduled Interactive Sessions)
              _buildLiveClassesSection(),
              const SizedBox(height: 16),

              // 📝 ACTIVE ASSESSMENTS & QUIZZES SECTION (Full list with marks & status)
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Text(
                          'Active Assessments',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (_assessments.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              '${_assessments.length} Available',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFBBF24),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AssessmentHistoryScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('History', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_assessments.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161F38),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF283548)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'No pending assessments right now! You are all caught up.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._assessments.map((a) {
                  final bool hasScore = a.bestScore != null;
                  final double score = a.bestScore ?? 0.0;
                  final bool isPassed = a.isPassed;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161F38),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isPassed
                            ? const Color(0xFF10B981).withValues(alpha: 0.4)
                            : (hasScore
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                                : const Color(0xFF283548)),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: isPassed
                                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                    : (hasScore
                                        ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                                        : AppTheme.primary.withValues(alpha: 0.15)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isPassed
                                    ? Icons.emoji_events_rounded
                                    : Icons.assignment_turned_in_rounded,
                                color: isPassed
                                    ? const Color(0xFF10B981)
                                    : (hasScore
                                        ? const Color(0xFFFBBF24)
                                        : AppTheme.primary),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: isPassed
                                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                              : (hasScore
                                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                                                  : const Color(0xFF3B82F6).withValues(alpha: 0.15)),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isPassed
                                              ? 'PASSED 🎉'
                                              : (hasScore ? 'SCORE: ${score.toStringAsFixed(1)}%' : 'QUIZ'),
                                          style: TextStyle(
                                            color: isPassed
                                                ? const Color(0xFF34D399)
                                                : (hasScore ? const Color(0xFFFBBF24) : const Color(0xFF60A5FA)),
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${a.totalQuestions} Qs • ${a.timeLimitMinutes}m • Pass: ${a.passPercentage}%',
                                          style: const TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 10,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    a.title,
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
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AssessmentScreen(
                                      assessment: a,
                                    ),
                                  ),
                                );
                                _loadData();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isPassed
                                    ? const Color(0xFF10B981)
                                    : (hasScore ? const Color(0xFFF59E0B) : AppTheme.primary),
                                foregroundColor: isPassed || !hasScore ? Colors.white : Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                hasScore ? 'Retake' : 'Start Test',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (hasScore) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (score / 100.0).clamp(0.0, 1.0),
                              backgroundColor: Colors.white10,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isPassed ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 16),
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

  // =========================================================================
  // 🎥 UPCOMING LIVE CLASSES SECTION (Just like Assessments)
  // =========================================================================
  Widget _buildLiveClassesSection() {
    final bool hasLive = _liveClasses.any((c) => c.isLive);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Live Classes',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                if (hasLive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEF4444)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle, color: Color(0xFFEF4444), size: 8),
                        SizedBox(width: 4),
                        Text(
                          'LIVE NOW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_liveClasses.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '${_liveClasses.length} Scheduled',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF60A5FA),
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20, color: AppTheme.textSecondary),
              tooltip: 'Refresh live classes',
              onPressed: () async {
                final list = await LiveClassService.getUpcomingLiveClasses();
                if (mounted) {
                  setState(() => _liveClasses = list);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_liveClasses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF161F38),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF283548)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.videocam_off_rounded, color: Color(0xFF60A5FA), size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'No live classes scheduled right now! Check back soon for upcoming sessions.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          )
        else
          ..._liveClasses.map((c) => _buildLiveClassCard(c)),
      ],
    );
  }

  Widget _buildLiveClassCard(LiveClassModel c) {
    final bool isLive = c.isLive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161F38),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLive
              ? const Color(0xFFEF4444).withValues(alpha: 0.6)
              : const Color(0xFF283548),
          width: isLive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isLive
                ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: isLive
                      ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                      : const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isLive ? Icons.sensors_rounded : Icons.videocam_rounded,
                  color: isLive ? const Color(0xFFEF4444) : const Color(0xFF60A5FA),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      c.description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isLive
                      ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                      : const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isLive ? 'LIVE' : c.platformName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isLive ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF283548), height: 1),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_rounded, size: 14, color: Color(0xFFFBBF24)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            c.instructorName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.access_time_filled_rounded, size: 13, color: Color(0xFF60A5FA)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${c.formattedTime} • ${c.durationMinutes}m',
                            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  if (c.meetingLink.isNotEmpty) {
                    final launched = await LiveClassService.joinMeeting(c.meetingLink);
                    if (!launched && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not open meeting app. Link copied to clipboard!'),
                          backgroundColor: Color(0xFFEF4444),
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Meeting link has not been published yet.'),
                      ),
                    );
                  }
                },
                icon: Icon(
                  isLive ? Icons.play_arrow_rounded : Icons.login_rounded,
                  size: 16,
                ),
                label: Text(
                  isLive ? 'Join Live Now' : 'Enter Room',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLive ? const Color(0xFFEF4444) : const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
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
          border: Border.all(color: const Color(0xFF283548)),
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
          color: const Color(0xFF161F38),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF283548)),
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
