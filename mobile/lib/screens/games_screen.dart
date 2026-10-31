import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/game_service.dart';
import 'balloon_pop_screen.dart';
import 'crossword_game_screen.dart';
import 'fill_blanks_game_screen.dart';
import 'flashcard_game_screen.dart';
import 'flappy_word_screen.dart';
import 'highway_racer_screen.dart';
import 'match_game_screen.dart';
import 'mcq_game_screen.dart';
import 'word_ninja_screen.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _ShowcaseGameItem {
  final String title;
  final String subtitle;
  final String imagePath;
  final IconData iconData;
  final Color accentColor;
  final List<String> tags;
  final VoidCallback onTap;

  const _ShowcaseGameItem({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.iconData,
    required this.accentColor,
    required this.tags,
    required this.onTap,
  });
}

class _GamesScreenState extends State<GamesScreen> with SingleTickerProviderStateMixin {
  List<MobileGameItem> _games = [];
  UserModel? _user;
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final games = await GameService.getDatabaseGames();
    final user = await AuthService.getUserProfile();
    if (mounted) {
      setState(() {
        _games = games;
        _user = user;
        _isLoading = false;
      });
    }
  }

  void _openHighwayRacer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HighwayRacerScreen(title: 'Highway Racer'),
      ),
    );
  }

  void _openWordNinja() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WordNinjaScreen(title: 'Word Ninja'),
      ),
    );
  }

  void _openFlappyWord() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FlappyWordScreen(title: 'Flappy Word'),
      ),
    );
  }

  void _openBalloonPop() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BalloonPopScreen(title: 'Balloon Word Pop'),
      ),
    );
  }

  void _openMatchGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MatchGameScreen(title: 'Match It: Pairs'),
      ),
    );
  }

  void _openSentenceBuilder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FillBlanksGameScreen(title: 'Fill in the Blanks'),
      ),
    );
  }

  void _openMcqArena() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const McqGameScreen(title: 'MCQ Quiz Arena'),
      ),
    );
  }

  void _openCrossword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CrosswordGameScreen(title: 'Crossword Quest'),
      ),
    );
  }

  void _openFlashcards() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FlashcardGameScreen(title: 'Flashcard Mastery'),
      ),
    );
  }

  List<_ShowcaseGameItem> get _allShowcaseGames => [
    // 1. Match It (Connect Pairs)
    _ShowcaseGameItem(
      title: 'Match It',
      subtitle: 'Connect Pairs',
      imagePath: 'assets/images/game_magic_forest.jpg',
      iconData: Icons.extension_rounded,
      accentColor: const Color(0xFF10B981),
      tags: ['all', 'puzzles', 'vocab'],
      onTap: _openMatchGame,
    ),

    // 2. Fill in the Blanks (Fillups / Sentence Builder)
    _ShowcaseGameItem(
      title: 'Fill in Blanks',
      subtitle: 'Sentence Fillups',
      imagePath: 'assets/images/game_letter_basket.jpg',
      iconData: Icons.edit_note_rounded,
      accentColor: const Color(0xFF8B5CF6),
      tags: ['all', 'puzzles', 'grammar'],
      onTap: _openSentenceBuilder,
    ),

    // 3. MCQ Arena (Rapid Grammar & Vocab Quiz)
    _ShowcaseGameItem(
      title: 'MCQ Arena',
      subtitle: 'Speed Quiz',
      imagePath: 'assets/images/game_soon_neon.jpg',
      iconData: Icons.quiz_rounded,
      accentColor: const Color(0xFF6366F1),
      tags: ['all', 'quizzes', 'grammar'],
      onTap: _openMcqArena,
    ),

    // 4. Crossword Quest (Vocabulary Grid)
    _ShowcaseGameItem(
      title: 'Crossword',
      subtitle: 'Word Grid Quest',
      imagePath: 'assets/images/game_soon_banyan.jpg',
      iconData: Icons.grid_on_rounded,
      accentColor: const Color(0xFF0D9488),
      tags: ['all', 'puzzles', 'vocab'],
      onTap: _openCrossword,
    ),

    // 5. Highway Racer (3-Lane Car Racer)
    _ShowcaseGameItem(
      title: 'Highway Racer',
      subtitle: '3-Lane Speedway',
      imagePath: 'assets/images/game_highway_racer.jpg',
      iconData: Icons.directions_car_rounded,
      accentColor: const Color(0xFF0284C7),
      tags: ['all', 'action'],
      onTap: _openHighwayRacer,
    ),

    // 6. Word Ninja (Katana Slicing Action)
    _ShowcaseGameItem(
      title: 'Word Ninja',
      subtitle: 'Katana Slice',
      imagePath: 'assets/images/game_word_ninja.jpg',
      iconData: Icons.sports_martial_arts_rounded,
      accentColor: const Color(0xFFE11D48),
      tags: ['all', 'action', 'vocab'],
      onTap: _openWordNinja,
    ),

    // 7. Flappy Word (Skyways Flight)
    _ShowcaseGameItem(
      title: 'Flappy Word',
      subtitle: 'Rainbow Flight',
      imagePath: 'assets/images/game_flappy_word.jpg',
      iconData: Icons.flight_takeoff_rounded,
      accentColor: const Color(0xFFF59E0B),
      tags: ['all', 'action'],
      onTap: _openFlappyWord,
    ),

    // 8. Balloon Word Pop (Sky Fiesta)
    _ShowcaseGameItem(
      title: 'Balloon Pop',
      subtitle: 'Pop Words',
      imagePath: 'assets/images/game_ocean_fishing.jpg',
      iconData: Icons.bubble_chart_rounded,
      accentColor: const Color(0xFFD946EF),
      tags: ['all', 'action', 'vocab'],
      onTap: _openBalloonPop,
    ),

    // 9. Flashcard Mastery (3D Flip Deck)
    _ShowcaseGameItem(
      title: 'Flashcards',
      subtitle: '3D Flip Decks',
      imagePath: 'assets/images/game_soon_temple.jpg',
      iconData: Icons.style_rounded,
      accentColor: const Color(0xFFEA580C),
      tags: ['all', 'quizzes', 'vocab'],
      onTap: _openFlashcards,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF0F7FF),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      );
    }

    final userStars = _user != null && _user!.xp > 0 ? _user!.xp : 513;
    final displayedGames = _allShowcaseGames
        .where((g) => _selectedFilter == 'all' || g.tags.contains(_selectedFilter))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D), // Deep Midnight Navy
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0F1D), // Midnight Navy Top
              Color(0xFF0F172A), // Deep Slate Navy
              Color(0xFF080D1A), // Dark Navy Bottom
            ],
            stops: [0.0, 0.45, 1.0],
          ),
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Games',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.15,
                              ),
                            ),
                            Text(
                              'Arena',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF818CF8),
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right Badge 1: 🎮 Games Count (e.g. 9 activities)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161F38),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF283548)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sports_esports_rounded, size: 16, color: Color(0xFF38BDF8)),
                            const SizedBox(width: 4),
                            Text(
                              '${_games.isNotEmpty ? _games.length : _allShowcaseGames.length}',
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

                      // Right Badge 2: ⭐ Stars / XP (e.g. 1475)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161F38),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF283548)),
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
                  // 🏷️ FILTER CHIPS HORIZONTAL ROW (Educational Categories)
                  // ==============================================================
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildChip(label: 'All Activities', key: 'all'),
                        const SizedBox(width: 10),
                        _buildChip(label: 'Action Games', key: 'action'),
                        const SizedBox(width: 10),
                        _buildChip(label: 'Puzzles & Words', key: 'puzzles'),
                        const SizedBox(width: 10),
                        _buildChip(label: 'Quizzes & Cards', key: 'quizzes'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ==============================================================
                  // 🎮 MAIN SHOWCASE 2-COLUMN GRID (All Real Activities with Bouncy Animations)
                  // ==============================================================
                  ..._buildGameGridRows(displayedGames),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build rows of pairs of game cards
  List<Widget> _buildGameGridRows(List<_ShowcaseGameItem> items) {
    List<Widget> rows = [];
    for (int i = 0; i < items.length; i += 2) {
      final item1 = items[i];
      final item2 = (i + 1 < items.length) ? items[i + 1] : null;

      rows.add(
        Row(
          children: [
            Expanded(
              child: _AnimatedGameCard(item: item1),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: item2 != null
                  ? _AnimatedGameCard(item: item2)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );

      if (i + 2 < items.length) {
        rows.add(const SizedBox(height: 14));
      }
    }
    return rows;
  }

  // Filter Chip Widget
  Widget _buildChip({required String label, required String key}) {
    final bool isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF161F38),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF818CF8) : const Color(0xFF283548),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// Stateful Animated Game Card with Touch-Scale Spring Physics & Live 70% Original Animations
class _AnimatedGameCard extends StatefulWidget {
  final _ShowcaseGameItem item;

  const _AnimatedGameCard({required this.item});

  @override
  State<_AnimatedGameCard> createState() => _AnimatedGameCardState();
}

class _AnimatedGameCardState extends State<_AnimatedGameCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _buildGameLiveAnimation(String title, double animValue) {
    if (title.contains('Highway Racer')) {
      return CustomPaint(
        painter: _HighwayRacerPainter(progress: animValue),
      );
    } else if (title.contains('Flappy Word')) {
      return CustomPaint(
        painter: _FlappyBirdPainter(progress: animValue),
      );
    } else if (title.contains('Balloon Pop')) {
      return CustomPaint(
        painter: _BalloonPopPainter(progress: animValue),
      );
    } else if (title.contains('Word Ninja')) {
      return CustomPaint(
        painter: _WordNinjaPainter(progress: animValue),
      );
    } else {
      return CustomPaint(
        painter: _MagicalSparklesPainter(
          progress: animValue,
          accentColor: widget.item.accentColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        item.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
        child: AspectRatio(
          aspectRatio: 1.45,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withValues(alpha: _isPressed ? 0.05 : 0.12),
                  blurRadius: _isPressed ? 4 : 10,
                  offset: Offset(0, _isPressed ? 2 : 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Background Image
                  Image.asset(
                    item.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: item.accentColor,
                      child: Center(
                        child: Icon(item.iconData, color: Colors.white, size: 36),
                      ),
                    ),
                  ),

                  // 2. 🌟 70% ORIGINAL LIVE ANIMATIONS (Moving Car, Flying Bird, Floating Balloons, Katana Slash, Sparkles)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _animController,
                        builder: (context, _) => _buildGameLiveAnimation(
                          item.title,
                          _animController.value,
                        ),
                      ),
                    ),
                  ),

                  // 3. Subtle dark vignette gradient for text contrast
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.30),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.70),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),

                  // 4. Top-Left Circular Icon Badge with Accent Ring
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.60),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: item.accentColor.withValues(alpha: 0.8),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(item.iconData, color: Colors.white, size: 16),
                      ),
                    ),
                  ),

                  // 5. Bottom Title (Simple clean game name without black box)
                  Positioned(
                    bottom: 12,
                    left: 8,
                    right: 8,
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1.5),
                            blurRadius: 4,
                            color: Colors.black,
                          ),
                        ],
                      ),
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
}

// ==============================================================================
// 🏎️ 1. Highway Racer Live Animation: Moving Sports Car with Headlights & Speed Trails
// ==============================================================================
class _HighwayRacerPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  _HighwayRacerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Car moves continuously across the lower road area
    final double carX = (progress * (size.width + 120)) - 60;
    final double roadY = size.height * 0.65;
    final double carY = roadY + math.sin(progress * 50 * math.pi) * 0.7;

    final Paint paint = Paint()..isAntiAlias = true;

    // 1. Headlight glow beam shining forward
    final Path headlightPath = Path()
      ..moveTo(carX + 32, carY - 2)
      ..lineTo(carX + 75, carY - 12)
      ..lineTo(carX + 75, carY + 12)
      ..close();

    final Paint headlightPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.amberAccent.withValues(alpha: 0.45),
          Colors.yellow.withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromLTWH(carX + 32, carY - 12, 45, 24));
    canvas.drawPath(headlightPath, headlightPaint);

    // 2. Neon Red/Cyan Speed Streak Trail behind car
    for (int i = 0; i < 3; i++) {
      final double trailOffset = 8.0 * (i + 1);
      final double trailAlpha = (0.65 - i * 0.18).clamp(0.0, 1.0);
      final Paint trailPaint = Paint()
        ..color = (i % 2 == 0 ? const Color(0xFFEF4444) : const Color(0xFF38BDF8))
            .withValues(alpha: trailAlpha)
        ..strokeWidth = 2.0 - i * 0.5
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(carX - 2 - trailOffset * 1.5, carY - 1 + i * 2.5),
        Offset(carX - 2, carY - 1 + i * 2.5),
        trailPaint,
      );
    }

    // 3. Neon Underglow
    final Paint underglow = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(carX + 14, carY + 6), width: 34, height: 7),
      underglow,
    );

    // 4. Car Body (Sleek Red Sports Car)
    final RRect chassis = RRect.fromRectAndRadius(
      Rect.fromLTWH(carX, carY - 2, 32, 9),
      const Radius.circular(3),
    );
    paint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFF4D4D), Color(0xFFB91C1C)],
    ).createShader(Rect.fromLTWH(carX, carY - 2, 32, 9));
    paint.style = PaintingStyle.fill;
    canvas.drawRRect(chassis, paint);

    // Cabin / Roof & Windshield
    final Path cabin = Path()
      ..moveTo(carX + 7, carY - 2)
      ..lineTo(carX + 12, carY - 7)
      ..lineTo(carX + 22, carY - 7)
      ..lineTo(carX + 27, carY - 2)
      ..close();
    paint.shader = const LinearGradient(
      colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
    ).createShader(Rect.fromLTWH(carX + 7, carY - 7, 20, 5));
    canvas.drawPath(cabin, paint);

    // Roof white shine line
    final Paint roofShine = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(carX + 13, carY - 6.5), Offset(carX + 21, carY - 6.5), roofShine);

    // Rear Spoiler
    paint.shader = null;
    paint.color = const Color(0xFF991B1B);
    canvas.drawRect(Rect.fromLTWH(carX - 2, carY - 6, 3, 4), paint);
    canvas.drawRect(Rect.fromLTWH(carX - 3, carY - 7, 5, 1.8), paint);

    // Headlight bulb
    paint.color = Colors.yellowAccent;
    canvas.drawCircle(Offset(carX + 31, carY + 1), 1.8, paint);

    // Tail light
    paint.color = const Color(0xFFFF2222);
    canvas.drawCircle(Offset(carX + 1, carY + 1), 1.6, paint);

    // Wheels (Front & Rear)
    final Paint wheelPaint = Paint()..color = const Color(0xFF1E293B);
    final Paint rimPaint = Paint()..color = const Color(0xFFE2E8F0);
    // Rear wheel
    canvas.drawCircle(Offset(carX + 6, carY + 7), 3.5, wheelPaint);
    canvas.drawCircle(Offset(carX + 6, carY + 7), 1.5, rimPaint);
    // Front wheel
    canvas.drawCircle(Offset(carX + 25, carY + 7), 3.5, wheelPaint);
    canvas.drawCircle(Offset(carX + 25, carY + 7), 1.5, rimPaint);
  }

  @override
  bool shouldRepaint(_HighwayRacerPainter oldDelegate) => oldDelegate.progress != progress;
}

// ==============================================================================
// 🐦 2. Flappy Word Live Animation: Bobbing & Wing-Flapping Bird with Clouds & Trails
// ==============================================================================
class _FlappyBirdPainter extends CustomPainter {
  final double progress;

  _FlappyBirdPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Drifting soft white clouds in background
    final Paint cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 2; i++) {
      final double cloudP = (progress * 0.7 + i * 0.5) % 1.0;
      final double cx = size.width * (1.1 - cloudP * 1.3);
      final double cy = size.height * (0.2 + i * 0.25);
      canvas.drawCircle(Offset(cx, cy), 10, cloudPaint);
      canvas.drawCircle(Offset(cx + 8, cy - 3), 8, cloudPaint);
      canvas.drawCircle(Offset(cx - 7, cy - 1), 7, cloudPaint);
      canvas.drawCircle(Offset(cx + 5, cy + 3), 7, cloudPaint);
    }

    // 2. Flying Bird with bobbing sinusoidal motion
    final double bx = size.width * 0.45 + math.sin(progress * 2 * math.pi) * 16;
    final double by = size.height * 0.42 + math.sin(progress * 4 * math.pi) * 10;
    final double tilt = math.cos(progress * 4 * math.pi) * -0.20;

    canvas.save();
    canvas.translate(bx, by);
    canvas.rotate(tilt);

    // Magic sparkle trail behind the bird
    for (int i = 0; i < 3; i++) {
      final double trailX = -14.0 - i * 7.0;
      final double trailY = math.sin(progress * 8 * math.pi + i) * 4.0;
      final double trailAlpha = (0.7 - i * 0.22).clamp(0.0, 1.0);
      final Paint trailPaint = Paint()
        ..color = (i == 0 ? Colors.amberAccent : Colors.lightBlueAccent).withValues(alpha: trailAlpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(trailX, trailY), 2.2 - i * 0.5, trailPaint);
    }

    final Paint paint = Paint()..isAntiAlias = true;

    // Bird Round Body (Vibrant Yellow Gradient)
    paint.shader = const RadialGradient(
      center: Alignment(-0.2, -0.3),
      colors: [Color(0xFFFEF08A), Color(0xFFFACC15), Color(0xFFEAB308)],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: 11));
    canvas.drawCircle(Offset.zero, 11, paint);

    // Cute White/Black Cartoon Eye
    paint.shader = null;
    paint.color = Colors.white;
    canvas.drawCircle(const Offset(4, -3), 4.2, paint);
    paint.color = const Color(0xFF0F172A);
    canvas.drawCircle(const Offset(5.2, -3), 2.1, paint);
    paint.color = Colors.white;
    canvas.drawCircle(const Offset(6.0, -4.0), 1.0, paint); // eye shine

    // Orange Beak
    final Path beak = Path()
      ..moveTo(9, -2)
      ..lineTo(16, 0)
      ..lineTo(9, 3)
      ..close();
    paint.color = const Color(0xFFF97316);
    canvas.drawPath(beak, paint);

    // Fluttering Wing (Fast flapping oscillation!)
    final double wingAngle = math.sin(progress * 14 * math.pi) * 0.55;
    canvas.save();
    canvas.translate(-2, 1);
    canvas.rotate(wingAngle);
    final Path wing = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-8, -10, -12, -4)
      ..quadraticBezierTo(-8, 3, 0, 2)
      ..close();
    paint.color = const Color(0xFFF59E0B);
    canvas.drawPath(wing, paint);
    canvas.restore();

    // Little cute crest / feather on top
    final Path crest = Path()
      ..moveTo(-1, -10)
      ..quadraticBezierTo(-4, -15, 0, -16)
      ..quadraticBezierTo(2, -13, 2, -10)
      ..close();
    paint.color = const Color(0xFFEAB308);
    canvas.drawPath(crest, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_FlappyBirdPainter oldDelegate) => oldDelegate.progress != progress;
}

// ==============================================================================
// 🎈 3. Balloon Pop Live Animation: Floating Rising Balloons & Pop Sparkles
// ==============================================================================
class _BalloonPopPainter extends CustomPainter {
  final double progress;

  _BalloonPopPainter({required this.progress});

  static const List<Color> _balloonColors = [
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEC4899), // Pink
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Purple
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 4; i++) {
      final double p = (progress + i * 0.26) % 1.0;
      final double bx = size.width * (0.20 + i * 0.22) + math.sin(p * 4 * math.pi + i) * 6;
      final double by = size.height * (1.15 - p * 1.35);

      if (p < 0.88) {
        // Floating Balloon
        final Color color = _balloonColors[i % _balloonColors.length];
        final Paint bPaint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.4),
            colors: [
              Colors.white.withValues(alpha: 0.9),
              color,
              color.withValues(alpha: 0.85),
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(Rect.fromLTWH(bx - 8, by - 11, 16, 22));

        // Balloon oval
        canvas.drawOval(Rect.fromLTWH(bx - 8, by - 11, 16, 22), bPaint);

        // Knot
        final Paint knotPaint = Paint()..color = color;
        canvas.drawCircle(Offset(bx, by + 11.5), 1.5, knotPaint);

        // Trailing string
        final Path stringPath = Path()
          ..moveTo(bx, by + 12)
          ..quadraticBezierTo(bx - 2, by + 17, bx + 1, by + 23);
        final Paint stringPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke;
        canvas.drawPath(stringPath, stringPaint);
      } else {
        // Popping star sparkles
        final double popProgress = (p - 0.88) / 0.12;
        final double radius = popProgress * 14.0;
        final double alpha = (1.0 - popProgress).clamp(0.0, 1.0);
        final Paint popPaint = Paint()
          ..color = _balloonColors[i % _balloonColors.length].withValues(alpha: alpha);

        for (int s = 0; s < 5; s++) {
          final double angle = s * (2 * math.pi / 5);
          final double sx = bx + math.cos(angle) * radius;
          final double sy = by + math.sin(angle) * radius;
          canvas.drawCircle(Offset(sx, sy), 1.8 * (1.0 - popProgress), popPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_BalloonPopPainter oldDelegate) => oldDelegate.progress != progress;
}

// ==============================================================================
// ⚔️ 4. Word Ninja Live Animation: Spinning Shuriken & Glowing Katana Slash
// ==============================================================================
class _WordNinjaPainter extends CustomPainter {
  final double progress;

  _WordNinjaPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Spinning Shuriken in top right
    final double sx = size.width - 24;
    final double sy = 24;
    final double shurikenRotation = progress * 6 * math.pi;

    canvas.save();
    canvas.translate(sx, sy);
    canvas.rotate(shurikenRotation);

    final Paint shurikenPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.fill;

    final Path shurikenPath = Path();
    for (int i = 0; i < 4; i++) {
      final double angle = i * (math.pi / 2);
      final double tipX = math.cos(angle) * 11;
      final double tipY = math.sin(angle) * 11;
      final double midAngle = angle + (math.pi / 4);
      final double midX = math.cos(midAngle) * 3;
      final double midY = math.sin(midAngle) * 3;

      if (i == 0) {
        shurikenPath.moveTo(tipX, tipY);
      } else {
        shurikenPath.lineTo(tipX, tipY);
      }
      shurikenPath.lineTo(midX, midY);
    }
    shurikenPath.close();
    canvas.drawPath(shurikenPath, shurikenPaint);

    final Paint centerPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawCircle(Offset.zero, 2.2, centerPaint);
    canvas.restore();

    // 2. Periodic Katana Slash Gleam across card
    if (progress >= 0.35 && progress <= 0.65) {
      final double slashP = (progress - 0.35) / 0.30;
      final double startX = size.width * (0.1 + slashP * 0.7);
      final double startY = size.height * (0.2 + slashP * 0.6);
      final double endX = startX - 50;
      final double endY = startY - 35;

      final double slashAlpha = math.sin(slashP * math.pi);

      final Paint slashGlow = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: slashAlpha * 0.8)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawLine(Offset(endX, endY), Offset(startX, startY), slashGlow);

      final Paint slashCore = Paint()
        ..color = Colors.white.withValues(alpha: slashAlpha)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(endX, endY), Offset(startX, startY), slashCore);
    }
  }

  @override
  bool shouldRepaint(_WordNinjaPainter oldDelegate) => oldDelegate.progress != progress;
}

// ==============================================================================
// ✨ 5. Magical Sparkles Live Animation (Match It, Fill Blanks, Crossword, MCQ Arena)
// ==============================================================================
class _MagicalSparklesPainter extends CustomPainter {
  final double progress;
  final Color accentColor;

  _MagicalSparklesPainter({required this.progress, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 5; i++) {
      final double p = (progress + i * 0.22) % 1.0;
      final double px = size.width * (0.15 + i * 0.18) + math.sin(p * 3 * math.pi + i) * 7;
      final double py = size.height * (0.85 - p * 0.75);

      final double pulse = math.sin(p * math.pi);
      final double alpha = (pulse * 0.75).clamp(0.0, 1.0);

      final Paint sparklePaint = Paint()
        ..color = (i % 2 == 0 ? accentColor : Colors.amberAccent).withValues(alpha: alpha);

      final double arm = 2.8 * pulse + 1.0;
      canvas.drawCircle(Offset(px, py), arm * 0.5, sparklePaint);
      canvas.drawLine(Offset(px - arm, py), Offset(px + arm, py), sparklePaint..strokeWidth = 0.9);
      canvas.drawLine(Offset(px, py - arm), Offset(px, py + arm), sparklePaint..strokeWidth = 0.9);
    }
  }

  @override
  bool shouldRepaint(_MagicalSparklesPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.accentColor != accentColor;
}
