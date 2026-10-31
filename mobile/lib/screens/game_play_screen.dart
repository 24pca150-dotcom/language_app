import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../data/game_question_bank.dart';
import '../services/game_service.dart';
import '../theme/app_theme.dart';

class GamePlayScreen extends StatefulWidget {
  final MobileGameItem game;

  const GamePlayScreen({super.key, required this.game});

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> with SingleTickerProviderStateMixin {
  // Common Game State
  int _score = 0;
  int _lives = 5;
  int _timeLeft = 30;
  bool _isGameOver = false;
  Timer? _gameTimer;

  // Word Ninja State
  final List<_NinjaWord> _ninjaWords = [];
  Timer? _ninjaSpawnTimer;

  // Highway Racer State
  int _carLane = 1; // 0: Left, 1: Middle, 2: Right
  int _currentRacerRound = 0;
  final List<Map<String, dynamic>> _racerRounds = [];

  // Balloon Pop State
  final List<_FloatingBalloon> _balloons = [];
  Timer? _balloonSpawnTimer;

  @override
  void initState() {
    super.initState();
    _setupRounds();
    _startGame();
  }

  void _setupRounds() {
    _racerRounds.clear();
    final racerPool = GameQuestionBank.getRandomRacerChallenges(5);
    for (var r in racerPool) {
      final opts = r['options'] as List;
      int correct = 0;
      List<String> lanes = [];
      for (int i = 0; i < opts.length; i++) {
        lanes.add(opts[i]['text'].toString());
        if (opts[i]['isCorrect'] == true) correct = i;
      }
      _racerRounds.add({
        'question': r['question'],
        'lanes': lanes,
        'correct': correct,
      });
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _ninjaSpawnTimer?.cancel();
    _balloonSpawnTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    _score = 0;
    _lives = 5;
    _timeLeft = 35;
    _isGameOver = false;

    // Countdown Timer
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        if (mounted) setState(() => _timeLeft--);
      } else {
        _endGame(won: true);
      }
    });

    if (widget.game.type.contains('ninja')) {
      _initWordNinja();
    } else if (widget.game.type.contains('balloon')) {
      _initBalloonPop();
    }
  }

  void _endGame({required bool won}) {
    _gameTimer?.cancel();
    _ninjaSpawnTimer?.cancel();
    _balloonSpawnTimer?.cancel();

    if (mounted) {
      setState(() => _isGameOver = true);
    }
  }

  // ===================== WORD NINJA GAME LOGIC =====================
  void _initWordNinja() {
    _spawnNinjaWordBatch();
    _ninjaSpawnTimer = Timer.periodic(const Duration(milliseconds: 1400), (t) {
      if (_isGameOver) return;
      _spawnNinjaWordBatch();
    });
  }

  void _spawnNinjaWordBatch() {
    final adjectives = ['Enormous', 'Silent', 'Swift', 'Brilliant', 'Gentle', 'Fierce', 'Sparkling', 'Ancient'];
    final nonAdjectives = ['Running', 'Jump', 'Tree', 'Elephant', 'Sing', 'Quickly', 'Book', 'Sleep'];

    final random = Random();
    final isCorrect = random.nextBool();
    final word = isCorrect
        ? adjectives[random.nextInt(adjectives.length)]
        : nonAdjectives[random.nextInt(nonAdjectives.length)];

    final fruitEmojis = ['🍉', '🍊', '🍎', '🍓', '🍍', '🍌', '🥝', '🥥'];
    final fruitEmoji = isCorrect
        ? fruitEmojis[random.nextInt(fruitEmojis.length)]
        : (random.nextDouble() < 0.4 ? '💣' : fruitEmojis[random.nextInt(fruitEmojis.length)]);

    final newWord = _NinjaWord(
      id: DateTime.now().millisecondsSinceEpoch + random.nextInt(100),
      text: word,
      isTarget: isCorrect,
      fruitEmoji: fruitEmoji,
      x: 0.15 + random.nextDouble() * 0.7,
      y: 0.2 + random.nextDouble() * 0.55,
      color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
    );

    if (mounted) {
      setState(() {
        if (_ninjaWords.length > 5) _ninjaWords.removeAt(0);
        _ninjaWords.add(newWord);
      });
    }
  }

  void _sliceWord(_NinjaWord word) {
    if (word.isSliced || _isGameOver) return;

    setState(() {
      word.isSliced = true;
      if (word.isTarget) {
        _score += 20;
      } else {
        _lives--;
        if (_lives <= 0) _endGame(won: false);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          word.isTarget ? '⚔️ SLICED "${word.text}"! (Adjective) +20 XP' : '💥 OUCH! "${word.text}" is NOT an Adjective! -1 Heart',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        duration: const Duration(milliseconds: 900),
        backgroundColor: word.isTarget ? AppTheme.secondary : AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ===================== HIGHWAY RACER LOGIC =====================
  void _steerCar(int newLane) {
    if (_isGameOver) return;
    setState(() => _carLane = newLane.clamp(0, 2));

    final current = _racerRounds[_currentRacerRound];
    final isHit = _carLane == current['correct'];

    if (isHit) {
      setState(() {
        _score += 50;
        if (_currentRacerRound < _racerRounds.length - 1) {
          _currentRacerRound++;
        } else {
          _endGame(won: true);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚡ TURBO BOOST! Correct lane hit! +50 Speed XP'),
          duration: Duration(milliseconds: 900),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _lives--;
        if (_lives <= 0) _endGame(won: false);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💥 Crash! Wrong lane word! -1 Heart'),
          duration: Duration(milliseconds: 900),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ===================== BALLOON POP LOGIC =====================
  void _initBalloonPop() {
    _spawnBalloon();
    _balloonSpawnTimer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      if (_isGameOver) return;
      _spawnBalloon();
    });
  }

  void _spawnBalloon() {
    final natureWords = ['Rain', 'Thunder', 'Breeze', 'Sunlight', 'Cloud', 'Storm'];
    final nonNatureWords = ['Laptop', 'Keyboard', 'Car', 'Plastic', 'Elevator', 'Train'];

    final random = Random();
    final isTarget = random.nextBool();
    final text = isTarget
        ? natureWords[random.nextInt(natureWords.length)]
        : nonNatureWords[random.nextInt(nonNatureWords.length)];

    final b = _FloatingBalloon(
      id: DateTime.now().millisecondsSinceEpoch + random.nextInt(50),
      text: text,
      isTarget: isTarget,
      color: Colors.primaries[random.nextInt(Colors.primaries.length)],
      x: 0.15 + random.nextDouble() * 0.7,
      y: 0.2 + random.nextDouble() * 0.55,
    );

    if (mounted) {
      setState(() {
        if (_balloons.length > 5) _balloons.removeAt(0);
        _balloons.add(b);
      });
    }
  }

  void _popBalloon(_FloatingBalloon b) {
    if (b.isPopped || _isGameOver) return;
    setState(() {
      b.isPopped = true;
      if (b.isTarget) {
        _score += 15;
      } else {
        _lives--;
        if (_lives <= 0) _endGame(won: false);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          b.isTarget ? '🎈 POPPED "${b.text}"! +15 XP' : '❌ "${b.text}" is not Nature/Weather! -1 Heart',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        duration: const Duration(milliseconds: 800),
        backgroundColor: b.isTarget ? AppTheme.secondary : AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNinja = widget.game.type.contains('ninja');
    final isRacer = widget.game.type.contains('racer');

    return Scaffold(
      backgroundColor: isNinja
          ? const Color(0xFF0F172A)
          : (isRacer ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: (isNinja || isRacer) ? Colors.white : AppTheme.textPrimary,
        ),
        title: Text(
          widget.game.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: (isNinja || isRacer) ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          // Hearts Display
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (idx) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Icon(
                  idx < _lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: Colors.redAccent,
                  size: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Score Pill
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, color: AppTheme.accent, size: 15),
                const SizedBox(width: 3),
                Text(
                  '$_score',
                  style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Game Arena Viewport
            Column(
              children: [
                // Game Mission Banner
                _buildMissionBanner(),

                // Main Game Interactive Canvas
                Expanded(
                  child: isNinja
                      ? _buildNinjaArena()
                      : (isRacer ? _buildRacerArena() : _buildBalloonArena()),
                ),
              ],
            ),

            // Game Over Overlay
            if (_isGameOver) _buildGameOverOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionBanner() {
    String missionText = '🎯 Mission: Tap or slice correct items!';
    if (widget.game.type.contains('ninja')) {
      missionText = '⚔️ SLICE ONLY ADJECTIVES! (Avoid Verbs & Nouns)';
    } else if (widget.game.type.contains('racer')) {
      missionText = '🏎️ STEER CAR INTO CORRECT PAST TENSE LANE!';
    } else if (widget.game.type.contains('balloon')) {
      missionText = '🎈 POP ONLY NATURE & WEATHER WORDS!';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              missionText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppTheme.primary,
              ),
            ),
          ),
          Text(
            '⏱️ ${_timeLeft}s',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryDark),
          ),
        ],
      ),
    );
  }

  // ==================== WORD NINJA ARENA ====================
  Widget _buildNinjaArena() {
    return GestureDetector(
      onPanUpdate: (details) {
        // Swipe to slice detection
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final local = details.localPosition;
        for (var w in _ninjaWords) {
          final targetX = w.x * box.size.width;
          final targetY = w.y * box.size.height;
          if ((local.dx - targetX).abs() < 55 && (local.dy - targetY).abs() < 55) {
            _sliceWord(w);
          }
        }
      },
      child: Container(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Background Katana Slash Effect Hint
            const Center(
              child: Text(
                'SWIPE ACROSS WORDS TO SLICE ⚔️',
                style: TextStyle(
                  color: Colors.white12,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            // Floating Ninja Words
            ..._ninjaWords.map((w) {
              return Positioned(
                left: MediaQuery.of(context).size.width * w.x - 60,
                top: (MediaQuery.of(context).size.height * 0.6) * w.y,
                child: GestureDetector(
                  onTap: () => _sliceWord(w),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: w.isSliced
                            ? [Colors.grey.shade800.withValues(alpha: 0.4), Colors.grey.shade900.withValues(alpha: 0.4)]
                            : [const Color(0xFF2E190E), const Color(0xFF140703)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(w.isSliced ? 6 : 14),
                      border: Border.all(
                        color: w.isSliced
                            ? Colors.grey.withValues(alpha: 0.3)
                            : (w.isTarget ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                        width: 1.8,
                      ),
                      boxShadow: w.isSliced
                          ? []
                          : [
                              BoxShadow(
                                color: (w.isTarget ? const Color(0xFFF59E0B) : const Color(0xFFEF4444))
                                    .withValues(alpha: 0.4),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!w.isSliced) ...[
                          Text(w.fruitEmoji, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                        ],
                        if (w.isSliced) ...[
                          const Icon(Icons.check, color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          w.isSliced ? '${w.fruitEmoji} SLICED 💥' : w.text,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            decoration: w.isSliced ? TextDecoration.lineThrough : null,
                          ),
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
    );
  }

  // ==================== HIGHWAY RACER ARENA ====================
  Widget _buildRacerArena() {
    final current = _racerRounds[_currentRacerRound];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Question Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              current['question'],
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 14),

          // 3 Lanes Road
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: Row(
                children: List.generate(3, (laneIdx) {
                  final laneText = (current['lanes'] as List)[laneIdx];
                  final isCarHere = _carLane == laneIdx;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _steerCar(laneIdx),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: laneIdx < 2
                                ? const BorderSide(color: Colors.white24, width: 2, style: BorderStyle.solid)
                                : BorderSide.none,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Lane Word Card coming down
                            Container(
                              margin: const EdgeInsets.only(top: 20),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Text(
                                laneText,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            // Player Car
                            if (isCarHere) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withValues(alpha: 0.6),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.directions_car_rounded, color: Colors.black, size: 38),
                              ),
                            ] else ...[
                              const SizedBox(height: 50),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Steer Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _carLane > 0 ? () => _steerCar(_carLane - 1) : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Steer Left'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              ),
              ElevatedButton.icon(
                onPressed: _carLane < 2 ? () => _steerCar(_carLane + 1) : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Steer Right'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ==================== BALLOON POP ARENA ====================
  Widget _buildBalloonArena() {
    return Stack(
      children: [
        const Center(
          child: Text(
            'TAP BALLOONS TO POP 🎈',
            style: TextStyle(
              color: Colors.black12,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        ..._balloons.map((b) {
          return Positioned(
            left: MediaQuery.of(context).size.width * b.x - 45,
            top: (MediaQuery.of(context).size.height * 0.6) * b.y,
            child: GestureDetector(
              onTap: () => _popBalloon(b),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: b.isPopped ? 0.0 : 1.0,
                child: Container(
                  width: 90,
                  height: 105,
                  decoration: BoxDecoration(
                    color: b.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: b.color.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        b.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ==================== GAME OVER POPUP ====================
  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _score > 0 ? '🎉 Victory! Challenge Completed' : '💔 Game Over!',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'You scored $_score XP in ${widget.game.title}!',
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Back to Games'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _startGame,
                child: const Text('Play Again 🔄'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NinjaWord {
  final int id;
  final String text;
  final bool isTarget;
  final String fruitEmoji;
  final double x;
  final double y;
  final Color color;
  bool isSliced = false;

  _NinjaWord({
    required this.id,
    required this.text,
    required this.isTarget,
    required this.fruitEmoji,
    required this.x,
    required this.y,
    required this.color,
  });
}

class _FloatingBalloon {
  final int id;
  final String text;
  final bool isTarget;
  final Color color;
  final double x;
  final double y;
  bool isPopped = false;

  _FloatingBalloon({
    required this.id,
    required this.text,
    required this.isTarget,
    required this.color,
    required this.x,
    required this.y,
  });
}
