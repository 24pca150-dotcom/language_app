import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import '../services/game_service.dart';
import 'activity_practice_screen.dart';
import 'balloon_pop_screen.dart';
import 'crossword_game_screen.dart';
import 'fill_blanks_game_screen.dart';
import 'flashcard_game_screen.dart';
import 'flappy_word_screen.dart';
import 'game_play_screen.dart';
import 'highway_racer_screen.dart';
import 'match_game_screen.dart';
import 'mcq_game_screen.dart';
import 'word_ninja_screen.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> with SingleTickerProviderStateMixin {
  List<MobileGameItem> _games = [];
  List<MobileCourseItem> _courses = [];
  List<MobileLevelInfo> _levels = [];
  UserModel? _user;

  /// Card id for games that belong to no (visible) course.
  static const int _generalCourseId = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final games = await GameService.getDatabaseGames();
    final courses = await CourseService.getCourses();
    final levels = await GameService.getLevels();
    final user = await AuthService.getUserProfile();
    if (mounted) {
      setState(() {
        _games = games;
        _courses = courses;
        _levels = levels;
        _user = user;
        _isLoading = false;
      });
    }
  }

  List<MobileGameItem> _activitiesOfCourse(int courseId) {
    if (courseId == _generalCourseId) {
      final known = _courses.map((c) => c.id).toSet();
      return _games.where((g) => g.courseId == null || !known.contains(g.courseId)).toList();
    }
    return _games.where((g) => g.courseId == courseId).toList();
  }

  /// Courses plus a "General Practice" card when some games have no course.
  List<MobileCourseItem> get _courseCards => [
        ..._courses,
        if (_activitiesOfCourse(_generalCourseId).isNotEmpty)
          MobileCourseItem(id: _generalCourseId, name: 'General Practice', code: '', description: 'Games not linked to a course'),
      ];

  void _openCourse(MobileCourseItem course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameCourseGroupsScreen(
          courseName: course.name,
          activities: _activitiesOfCourse(course.id),
          onOpenGame: _openGame,
          levels: _levels,
        ),
      ),
    );
  }

  Widget _buildCourseCard(MobileCourseItem course) {
    final activities = _activitiesOfCourse(course.id);
    final typeCount = activities.map((a) => activityTypeKey(a.type)).toSet().length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openCourse(course),
          child: Ink(
            height: 130,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              // Newest game picture the admin uploaded in this course; else a colour gradient
              image: gameCoverOf(activities).isNotEmpty && !gameCoverOf(activities).toLowerCase().endsWith('.svg')
                  ? DecorationImage(image: NetworkImage(gameCoverOf(activities)), fit: BoxFit.cover)
                  : null,
              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)]),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.black.withValues(alpha: 0.75), Colors.black.withValues(alpha: 0.2)],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          course.name,
                          style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${activities.length} questions • $typeCount activity types',
                          style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Enter', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openHighwayRacer([String title = 'Highway Racer']) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HighwayRacerScreen(title: title),
      ),
    );
  }

  void _openWordNinja([String title = 'Word Ninja']) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordNinjaScreen(title: title),
      ),
    );
  }

  void _openFlappyWord([String title = 'Flappy Word']) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlappyWordScreen(title: title),
      ),
    );
  }

  void _openBalloonPop([String title = 'Balloon Word Pop']) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BalloonPopScreen(title: title),
      ),
    );
  }

  void _openMatchGame([String title = 'Match It: Pairs']) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchGameScreen(title: title),
      ),
    );
  }

  void _openSentenceBuilder([String title = 'Fill in the Blanks']) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FillBlanksGameScreen(title: title),
      ),
    );
  }

  void _openMcqArena([String title = 'MCQ Quiz Arena']) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => McqGameScreen(title: title),
      ),
    );
  }

  void _openCrossword([String title = 'Crossword Quest']) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrosswordGameScreen(title: title),
      ),
    );
  }

  void _openFlashcards([String title = 'Flashcard Mastery']) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardGameScreen(title: title),
      ),
    );
  }

  void _openGame(MobileGameItem game) {
    final type = game.type.toLowerCase();
    if (type.contains('racer') || type.contains('car')) {
      _openHighwayRacer(game.title);
    } else if (type.contains('ninja')) {
      _openWordNinja(game.title);
    } else if (type.contains('flappy') || type.contains('bird')) {
      _openFlappyWord(game.title);
    } else if (type.contains('balloon')) {
      _openBalloonPop(game.title);
    } else if (type.contains('match')) {
      _openMatchGame(game.title);
    } else if (type.contains('blank') || type.contains('fill')) {
      _openSentenceBuilder(game.title);
    } else if (type.contains('mcq') || type.contains('quiz')) {
      _openMcqArena(game.title);
    } else if (type.contains('crossword')) {
      _openCrossword(game.title);
    } else if (type.contains('flashcard') || type.contains('card')) {
      _openFlashcards(game.title);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GamePlayScreen(game: game),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.bgLight,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );
    }

    final userStars = _user?.xp ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.bgLight, // Deep Midnight Navy
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: const Color(0xFF6366F1),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==============================================================
                  // 🌟 TOP HEADER ROW (English Games Arena)
                  // ==============================================================
                  Row(
                    children: [
                      // Only Cartoon Mascot (clean, no face icon or background box)
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: Image.asset(
                          'assets/images/mascot.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Two-line Title in English: Games / Arena
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Games',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Arena',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF818CF8),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right Badge 1: 🎮 Games Count (e.g. 0 or active count)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.boxBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sports_esports_rounded, size: 16, color: Color(0xFF38BDF8)),
                            const SizedBox(width: 4),
                            Text(
                              '${_games.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF38BDF8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Right Badge 2: ⭐ Stars / XP
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.boxBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFBBF24)),
                            const SizedBox(width: 4),
                            Text(
                              '$userStars',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFBBF24),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ==============================================================
                  // 📚 COURSES: pick a course -> activity types -> questions
                  // ==============================================================
                  Text(
                    'Choose a course',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  if (_courseCards.isEmpty)
                    _buildEmptyGamesState()
                  else
                    ..._courseCards.map(_buildCourseCard),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyGamesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.boxBorder, width: 1.5),
              ),
              child: const Icon(
                Icons.sports_esports_rounded,
                size: 54,
                color: Color(0xFF818CF8),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Games Added Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Activities created in the admin dashboard will automatically appear here with their matching game artwork and challenges.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh Games', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
