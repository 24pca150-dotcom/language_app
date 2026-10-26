import 'package:flutter/material.dart';
import '../services/game_service.dart';
import '../theme/app_theme.dart';
import 'balloon_pop_screen.dart';
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

class _GamesScreenState extends State<GamesScreen> {
  List<MobileGameItem> _games = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    final games = await GameService.getDatabaseGames();
    if (mounted) {
      setState(() {
        _games = games;
        _isLoading = false;
      });
    }
  }

  void _openGame(MobileGameItem game) {
    if (game.type.contains('flappy')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FlappyWordScreen(title: game.title),
        ),
      );
    } else if (game.type.contains('balloon')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BalloonPopScreen(title: game.title),
        ),
      );
    } else if (game.type.contains('ninja')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WordNinjaScreen(title: game.title),
        ),
      );
    } else if (game.type.contains('mcq')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => McqGameScreen(title: game.title),
        ),
      );
    } else if (game.type.contains('match')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MatchGameScreen(title: game.title),
        ),
      );
    } else if (game.type.contains('flashcard')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FlashcardGameScreen(title: game.title),
        ),
      );
    } else if (game.type.contains('fill_blanks')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FillBlanksGameScreen(title: game.title),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HighwayRacerScreen(title: game.title),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text(
          'Language Games',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Text('🪙', style: TextStyle(fontSize: 14)),
                SizedBox(width: 4),
                Text(
                  '180 Coins',
                  style: TextStyle(
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
      body: RefreshIndicator(
        onRefresh: _loadGames,
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Games Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF047857)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Interactive Game Arena! 🎮',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Play Speedway, Word Ninja, MCQ Arena, Match It & Vocab Decks from Web!',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('🏆', style: TextStyle(fontSize: 40)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All Activities', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('📝 MCQ & Drills', 'drills'),
                    const SizedBox(width: 8),
                    _buildFilterChip('🎮 Arcade Games', 'arcade'),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Game Cards
              ..._getFilteredGames().map((game) => _buildGameCard(game)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _selectedFilter = 'all';

  Widget _buildFilterChip(String label, String key) {
    final bool isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = key),
      selectedColor: AppTheme.primary,
      backgroundColor: AppTheme.boxColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.boxBorder,
        ),
      ),
    );
  }

  List<MobileGameItem> _getFilteredGames() {
    if (_selectedFilter == 'arcade') {
      return _games.where((g) => ['car_racer', 'word_ninja', 'flappy_word', 'balloon_pop'].contains(g.type)).toList();
    } else if (_selectedFilter == 'drills') {
      return _games.where((g) => ['mcq', 'match', 'flashcard', 'fill_blanks'].contains(g.type)).toList();
    }
    return _games;
  }

  Widget _buildGameCard(MobileGameItem game) {
    final Color color = game.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openGame(game),
            child: Stack(
              children: [
                // Colorful Left Accent Strip
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                  child: Row(
                    children: [
                      // 3D Game Icon Box
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color.withValues(alpha: 0.22),
                              color.withValues(alpha: 0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: color.withValues(alpha: 0.35)),
                        ),
                        child: Center(
                          child: Icon(game.icon, color: color, size: 30),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    game.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    game.badge,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              game.subtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.3,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFD97706)),
                                const SizedBox(width: 3),
                                Text(
                                  game.xp,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [color, color.withValues(alpha: 0.85)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Play',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
