import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../data/game_question_bank.dart';
import '../services/game_audio_service.dart';

class WordNinjaScreen extends StatefulWidget {
  final String title;

  const WordNinjaScreen({
    super.key,
    this.title = 'Word Ninja: Slice All Adjectives',
  });

  @override
  State<WordNinjaScreen> createState() => _WordNinjaScreenState();
}

class _NinjaItem {
  final int id;
  final String text;
  final bool isTarget;
  final Color color;
  final String fruitType;
  final Color juiceColor;
  final double radius = 42;
  double x;
  double y;
  double vx;
  double vy;
  double angle;
  double vRot;
  bool sliced = false;

  _NinjaItem({
    required this.id,
    required this.text,
    required this.isTarget,
    required this.color,
    required this.fruitType,
    required this.juiceColor,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.angle,
    required this.vRot,
  });
}

class _SlicePiece {
  final String text;
  final Color color;
  final String fruitType;
  final bool isLeft;
  final Color juiceColor;
  final double radius;
  double x;
  double y;
  double vx;
  double vy;
  double angle;
  double vRot;
  double opacity = 1.0;

  _SlicePiece({
    required this.text,
    required this.color,
    required this.fruitType,
    required this.isLeft,
    required this.juiceColor,
    required this.radius,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.angle,
    required this.vRot,
  });
}

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double radius;
  double life;
  double maxLife;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.radius,
    required this.life,
    required this.maxLife,
  });
}

class _FloatingFeedback {
  final String text;
  final Color color;
  double x;
  double y;
  double opacity = 1.0;

  _FloatingFeedback({
    required this.text,
    required this.color,
    required this.x,
    required this.y,
  });
}

class _NinjaChallenge {
  final String title;
  final String prompt;
  final List<String> targets;
  final List<String> distractors;

  _NinjaChallenge({
    required this.title,
    required this.prompt,
    required this.targets,
    required this.distractors,
  });
}

class _WordNinjaScreenState extends State<WordNinjaScreen> {
  int _score = 0;
  int _lives = 5;
  int _streak = 0;
  int _currentChallengeIndex = 0;
  int _challengeSlices = 0;
  final int _slicesPerChallenge = 3; // 3 slices per challenge, 5 challenges = 15 total
  String _gameState = 'playing'; // 'playing', 'victory', 'gameover'
  bool _soundEnabled = true;

  Timer? _loopTimer;
  double _spawnTimer = 0.5;
  int _idCounter = 0;

  final List<_NinjaItem> _items = [];
  final List<_SlicePiece> _pieces = [];
  final List<_Particle> _particles = [];
  final List<_FloatingFeedback> _feedbacks = [];
  final List<Offset> _bladeTrail = [];

  final List<_NinjaChallenge> _challenges = [];

  Offset? _lastTouch;

  @override
  void initState() {
    super.initState();
    _startNinjaGame();
  }

  @override
  void dispose() {
    _loopTimer?.cancel();
    super.dispose();
  }

  void _startNinjaGame() {
    _score = 0;
    _lives = 5;
    _streak = 0;
    _currentChallengeIndex = 0;
    _challengeSlices = 0;
    _gameState = 'playing';
    _items.clear();
    _pieces.clear();
    _particles.clear();
    _feedbacks.clear();
    _bladeTrail.clear();
    _spawnTimer = 0.4;

    _challenges.clear();
    final randomChallenges = GameQuestionBank.getRandomNinjaChallenges(5);
    for (int i = 0; i < randomChallenges.length; i++) {
      final c = randomChallenges[i];
      final titleStr = c['title'].toString().replaceFirst('Challenge: ', '');
      _challenges.add(_NinjaChallenge(
        title: titleStr,
        prompt: c['prompt'] as String,
        targets: List<String>.from(c['targets'] as List),
        distractors: List<String>.from(c['distractors'] as List),
      ));
    }

    _loopTimer?.cancel();
    // 60 FPS physics tick
    _loopTimer = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick(0.016));
  }

  void _tick(double dt) {
    if (_gameState != 'playing') return;

    final random = Random();

    // 1. Spawning
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _spawnTimer = 1.2 + random.nextDouble() * 0.6;
      _launchWordWave();
    }

    // 2. Update Floating Items (Physics Arc)
    const double gravity = 460;
    for (int i = _items.length - 1; i >= 0; i--) {
      final item = _items[i];
      item.x += item.vx * dt;
      item.y += item.vy * dt;
      item.vy += gravity * dt;
      item.angle += item.vRot * dt;

      // Drop off bottom
      if (item.y > 600) {
        // If an unsliced correct adjective fell, player missed it!
        if (item.isTarget && !item.sliced) {
          _streak = 0;
          _lives--;
          _feedbacks.add(_FloatingFeedback(
            text: 'MISSED! ⏱️',
            color: const Color(0xFFF97316),
            x: item.x,
            y: 500,
          ));
          if (_lives <= 0) {
            _triggerGameOver();
          }
        }
        _items.removeAt(i);
      }
    }

    // 3. Update Slice Pieces
    for (int i = _pieces.length - 1; i >= 0; i--) {
      final p = _pieces[i];
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += gravity * dt;
      p.angle += p.vRot * dt;
      p.opacity -= dt * 0.9;
      if (p.opacity <= 0 || p.y > 620) {
        _pieces.removeAt(i);
      }
    }

    // 4. Update Juice & Spark Particles
    for (int i = _particles.length - 1; i >= 0; i--) {
      final pt = _particles[i];
      pt.x += pt.vx * dt;
      pt.y += pt.vy * dt;
      pt.life -= dt;
      if (pt.life <= 0) {
        _particles.removeAt(i);
      }
    }

    // 5. Update Floating Feedbacks
    for (int i = _feedbacks.length - 1; i >= 0; i--) {
      final fb = _feedbacks[i];
      fb.y -= dt * 50;
      fb.opacity -= dt * 1.2;
      if (fb.opacity <= 0) {
        _feedbacks.removeAt(i);
      }
    }

    if (mounted) setState(() {});
  }

  void _launchWordWave() {
    final random = Random();
    final currentCh = _challenges[_currentChallengeIndex];
    // Launch 1 or 2 items
    final count = random.nextDouble() < 0.35 ? 2 : 1;

    final fruitTypes = ['watermelon', 'orange', 'apple', 'strawberry', 'banana', 'pineapple', 'kiwi', 'coconut'];

    for (int i = 0; i < count; i++) {
      final isTarget = random.nextDouble() < 0.65;
      final text = isTarget
          ? currentCh.targets[random.nextInt(currentCh.targets.length)]
          : currentCh.distractors[random.nextInt(currentCh.distractors.length)];

      final spawnX = 60.0 + random.nextDouble() * 220.0;
      final spawnY = 540.0;
      final vx = (random.nextDouble() - 0.5) * 120.0;
      final vy = -460.0 - random.nextDouble() * 90.0;

      String fruitType;
      Color juiceColor;

      if (isTarget) {
        fruitType = fruitTypes[random.nextInt(fruitTypes.length)];
      } else {
        fruitType = random.nextDouble() < 0.45 ? 'bomb' : fruitTypes[random.nextInt(fruitTypes.length)];
      }

      switch (fruitType) {
        case 'watermelon':
          juiceColor = const Color(0xFFEF4444);
          break;
        case 'orange':
          juiceColor = const Color(0xFFF97316);
          break;
        case 'apple':
          juiceColor = const Color(0xFFF43F5E);
          break;
        case 'strawberry':
          juiceColor = const Color(0xFFE11D48);
          break;
        case 'banana':
          juiceColor = const Color(0xFFEAB308);
          break;
        case 'pineapple':
          juiceColor = const Color(0xFFCA8A04);
          break;
        case 'kiwi':
          juiceColor = const Color(0xFF22C55E);
          break;
        case 'coconut':
          juiceColor = const Color(0xFFF8FAFC);
          break;
        case 'bomb':
        default:
          juiceColor = const Color(0xFFF59E0B);
          break;
      }

      _items.add(_NinjaItem(
        id: ++_idCounter,
        text: text,
        isTarget: isTarget,
        color: juiceColor,
        fruitType: fruitType,
        juiceColor: juiceColor,
        x: spawnX,
        y: spawnY,
        vx: vx,
        vy: vy,
        angle: (random.nextDouble() - 0.5) * 0.3,
        vRot: (random.nextDouble() - 0.5) * 1.5,
      ));
    }
  }

  void _handleSlice(Offset start, Offset end) {
    if (_gameState != 'playing') return;

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.sliced) continue;

      // Check distance from item center to slice segment
      final d = _distToSegment(Offset(item.x, item.y), start, end);
      if (d <= item.radius + 10) {
        _sliceItem(item);
      }
    }
  }

  double _distToSegment(Offset p, Offset v, Offset w) {
    final l2 = (v.dx - w.dx) * (v.dx - w.dx) + (v.dy - w.dy) * (v.dy - w.dy);
    if (l2 == 0) return (p - v).distance;
    double t = ((p.dx - v.dx) * (w.dx - v.dx) + (p.dy - v.dy) * (w.dy - v.dy)) / l2;
    t = t.clamp(0.0, 1.0);
    final proj = Offset(v.dx + t * (w.dx - v.dx), v.dy + t * (w.dy - v.dy));
    return (p - proj).distance;
  }

  void _sliceItem(_NinjaItem item) {
    item.sliced = true;
    GameAudioService.playKnifeSlice();

    // Slice pieces
    final mid = (item.text.length / 2).ceil();
    final leftText = item.text.substring(0, mid);
    final rightText = item.text.substring(mid);

    _pieces.add(_SlicePiece(
      text: leftText,
      color: item.color,
      fruitType: item.fruitType,
      isLeft: true,
      juiceColor: item.juiceColor,
      radius: item.radius * 0.85,
      x: item.x - 14,
      y: item.y,
      vx: item.vx - 70,
      vy: item.vy - 40,
      angle: item.angle,
      vRot: -3.5,
    ));

    _pieces.add(_SlicePiece(
      text: rightText,
      color: item.color,
      fruitType: item.fruitType,
      isLeft: false,
      juiceColor: item.juiceColor,
      radius: item.radius * 0.85,
      x: item.x + 14,
      y: item.y,
      vx: item.vx + 70,
      vy: item.vy - 40,
      angle: item.angle,
      vRot: 3.5,
    ));

    if (item.isTarget) {
      // SUCCESS SLICE
      GameAudioService.playCorrectDing();
      _challengeSlices++;
      _streak++;
      final bonus = 100 + (_streak >= 2 ? _streak * 20 : 0);
      _score += bonus;

      // Juice Splatter in authentic fruit color
      _addSplatter(item.x, item.y, item.juiceColor, 28);

      // Feedback Text
      final comboStr = _streak >= 2 ? ' 🔥 ${_streak}x COMBO!' : '';
      _feedbacks.add(_FloatingFeedback(
        text: '+$bonus XP$comboStr',
        color: const Color(0xFF34D399),
        x: item.x,
        y: item.y - 20,
      ));

      // Advance through the 5 Challenges
      if (_challengeSlices >= _slicesPerChallenge) {
        if (_currentChallengeIndex < _challenges.length - 1) {
          _currentChallengeIndex++;
          _challengeSlices = 0;
          _items.clear();
          _feedbacks.add(_FloatingFeedback(
            text: 'ROUND ${_currentChallengeIndex + 1} CLEARED! 🌟',
            color: const Color(0xFFFBBF24),
            x: 180,
            y: 200,
          ));
        } else {
          _triggerVictory();
        }
      }
    } else {
      // WRONG SLICE (Bomb / Distractor)
      GameAudioService.playWrongBuzz();
      _streak = 0;
      _lives--;
      _addSplatter(item.x, item.y, item.juiceColor, 34);

      _feedbacks.add(_FloatingFeedback(
        text: item.fruitType == 'bomb' ? '💥 BOOM! BOMB! -1 ❤️' : 'WRONG! -1 ❤️',
        color: const Color(0xFFEF4444),
        x: item.x,
        y: item.y - 20,
      ));

      if (_lives <= 0) {
        _triggerGameOver();
      }
    }
  }

  void _addSplatter(double x, double y, Color color, int count) {
    final random = Random();
    for (int i = 0; i < count; i++) {
      final angle = random.nextDouble() * pi * 2;
      final speed = 50.0 + random.nextDouble() * 180.0;
      _particles.add(_Particle(
        x: x,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        color: color,
        radius: 2.5 + random.nextDouble() * 4.0,
        life: 0.4 + random.nextDouble() * 0.35,
        maxLife: 0.75,
      ));
    }
  }

  void _triggerVictory() {
    _gameState = 'victory';
  }

  void _triggerGameOver() {
    _gameState = 'gameover';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white24, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  // 1. 🥋 Real Word Ninja Dojo Background
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/game_word_ninja.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF0F172A)),
                    ),
                  ),

                  // 2. Dojo Atmospheric Shadow Vignette Gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.72),
                            Colors.black.withValues(alpha: 0.35),
                            Colors.black.withValues(alpha: 0.72),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Column(
                    children: [
                      // Top HUD Bar
                      _buildTopHud(),

                      // Mission Objective Banner
                      _buildObjectiveBanner(),

                      // Dojo Slicing Arena
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (details) {
                                final p = details.localPosition;
                                _lastTouch = p;
                                setState(() {
                                  _bladeTrail.clear();
                                  _bladeTrail.add(p);
                                });
                              },
                              onPanUpdate: (details) {
                                final p = details.localPosition;
                                if (_lastTouch != null) {
                                  _handleSlice(_lastTouch!, p);
                                }
                                _lastTouch = p;
                                setState(() {
                                  _bladeTrail.add(p);
                                  if (_bladeTrail.length > 12) _bladeTrail.removeAt(0);
                                });
                              },
                              onPanEnd: (_) {
                                _lastTouch = null;
                                setState(() => _bladeTrail.clear());
                              },
                              onTapDown: (details) {
                                final p = details.localPosition;
                                _handleSlice(p, p);
                              },
                              child: Stack(
                                children: [
                                  // Dojo Background Canvas
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _NinjaArenaPainter(
                                        items: _items,
                                        pieces: _pieces,
                                        particles: _particles,
                                        feedbacks: _feedbacks,
                                        bladeTrail: _bladeTrail,
                                      ),
                                    ),
                                  ),

                                  // Hint Overlay
                                  const Positioned(
                                    bottom: 16,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Text(
                                        '⚔️ SWIPE ACROSS FLYING WORDS TO SLICE',
                                        style: TextStyle(
                                          color: Colors.white24,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  // Victory / Game Over Overlay
                  if (_gameState == 'victory') _buildVictoryOverlay(),
                  if (_gameState == 'gameover') _buildGameOverOverlay(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHud() {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 4),
              Text(
                '$_score',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              if (_streak >= 2) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange, width: 0.8),
                  ),
                  child: Text(
                    '⚡${_streak}x',
                    style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'CHALLENGE ${_currentChallengeIndex + 1}/${_challenges.length}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...List.generate(
                5,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0.5),
                  child: Icon(
                    i < _lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: i < _lives ? const Color(0xFFEF4444) : Colors.white24,
                    size: 14,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => setState(() => _soundEnabled = !_soundEnabled),
                child: Icon(
                  _soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildObjectiveBanner() {
    final currentCh = _challenges[_currentChallengeIndex];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1B4B).withValues(alpha: 0.92),
            const Color(0xFF0F172A).withValues(alpha: 0.90),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.8),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.35),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.content_cut_rounded, color: Color(0xFFF59E0B), size: 13),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'CHALLENGE ${_currentChallengeIndex + 1}/5: ${currentCh.title.toUpperCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            currentCh.prompt,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              height: 1.25,
              shadows: [
                Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVictoryOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 64),
              const SizedBox(height: 12),
              const Text(
                '🎉 MASTER NINJA!',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'All target adjectives sliced with perfection!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Final Score: ', style: TextStyle(color: Colors.white70)),
                    Text(
                      '$_score pts',
                      style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _startNinjaGame,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Slice Again', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.heart_broken_rounded, color: Color(0xFFEF4444), size: 64),
              const SizedBox(height: 12),
              const Text(
                'OUT OF HEARTS!',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Careful! Only slice Adjectives, avoid bombs and wrong words.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  'Score: $_score pts',
                  style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _startNinjaGame,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- CANVAS PAINTER (AUTHENTIC ORIGINAL FRUITS / SLICED HALVES / KATANA SLASH TRAIL) ---
class _NinjaArenaPainter extends CustomPainter {
  final List<_NinjaItem> items;
  final List<_SlicePiece> pieces;
  final List<_Particle> particles;
  final List<_FloatingFeedback> feedbacks;
  final List<Offset> bladeTrail;

  _NinjaArenaPainter({
    required this.items,
    required this.pieces,
    required this.particles,
    required this.feedbacks,
    required this.bladeTrail,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Juice Particles
    for (final pt in particles) {
      final pPaint = Paint()
        ..color = pt.color.withValues(alpha: (pt.life / pt.maxLife).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(pt.x, pt.y), pt.radius, pPaint);

      // Droplet shine
      final shinePaint = Paint()
        ..color = Colors.white.withValues(alpha: (pt.life / pt.maxLife * 0.6).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(pt.x - pt.radius * 0.3, pt.y - pt.radius * 0.3), pt.radius * 0.35, shinePaint);
    }

    // 2. Floating Unsliced Whole Fruits
    for (final item in items) {
      if (item.sliced) continue;

      canvas.save();
      canvas.translate(item.x, item.y);
      canvas.rotate(item.angle);

      // Shadow
      final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.38);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(0, item.radius + 6), width: item.radius * 1.8, height: 16),
        shadowPaint,
      );

      // Draw original fruit body
      _drawFruitBody(canvas, item.fruitType, item.radius);

      // Word tag banner (Wooden Plaque)
      _drawWordBanner(canvas, item.text, item.radius, item.fruitType == 'bomb');

      canvas.restore();
    }

    // 3. Sliced Pieces (Two fruit halves flying apart)
    for (final p in pieces) {
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.angle);

      _drawSlicedFruitHalf(canvas, p.fruitType, p.radius, p.isLeft, p.opacity);
      _drawSlicedBanner(canvas, p.text, p.isLeft, p.opacity);

      canvas.restore();
    }

    // 4. Floating Feedbacks
    for (final fb in feedbacks) {
      final tp = TextPainter(
        text: TextSpan(
          text: fb.text,
          style: TextStyle(
            color: fb.color.withValues(alpha: fb.opacity.clamp(0.0, 1.0)),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 6),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(fb.x - tp.width / 2, fb.y));
    }

    // 5. Katana Slash Blade Trail (Glowing razor trail)
    if (bladeTrail.length >= 2) {
      for (int i = 0; i < bladeTrail.length - 1; i++) {
        final p1 = bladeTrail[i];
        final p2 = bladeTrail[i + 1];
        final progress = (i + 1) / bladeTrail.length;

        // Outer glow
        final glowPaint = Paint()
          ..color = const Color(0xFF38BDF8).withValues(alpha: progress * 0.75)
          ..strokeWidth = progress * 10.0
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(p1, p2, glowPaint);

        // Razor core (Bright white)
        final corePaint = Paint()
          ..color = Colors.white.withValues(alpha: progress * 0.95)
          ..strokeWidth = progress * 4.0
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(p1, p2, corePaint);
      }
    }
  }

  // --- DRAW WHOLE FRUIT BODY ---
  void _drawFruitBody(Canvas canvas, String fruitType, double r) {
    switch (fruitType) {
      case 'watermelon':
        // Watermelon body with stripes
        final bodyPaint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.3),
            radius: 0.9,
            colors: const [Color(0xFF22C55E), Color(0xFF16A34A), Color(0xFF14532D)],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
        canvas.drawCircle(Offset.zero, r, bodyPaint);

        // Dark green wavy stripes
        final stripePaint = Paint()
          ..color = const Color(0xFF052E16)
          ..strokeWidth = 4.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        for (final offset in [-r * 0.65, -r * 0.3, 0.0, r * 0.3, r * 0.65]) {
          final p = Path();
          p.moveTo(offset, -r * 0.85);
          p.cubicTo(offset - 6, -r * 0.3, offset + 6, r * 0.3, offset, r * 0.85);
          canvas.drawPath(p, stripePaint);
        }

        // Stem
        final stemPaint = Paint()
          ..color = const Color(0xFF78350F)
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        final stemPath = Path()..moveTo(0, -r)..quadraticBezierTo(8, -r - 10, 12, -r - 8);
        canvas.drawPath(stemPath, stemPaint);
        break;

      case 'orange':
        final bodyPaint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.3),
            radius: 0.9,
            colors: const [Color(0xFFFED7AA), Color(0xFFFB923C), Color(0xFFEA580C), Color(0xFF9A3412)],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
        canvas.drawCircle(Offset.zero, r, bodyPaint);

        // Top stem and leaf
        canvas.drawRect(Rect.fromLTWH(-2.5, -r - 5, 5, 6), Paint()..color = const Color(0xFF78350F));
        final leafPath = Path()
          ..addOval(Rect.fromCenter(center: Offset(10, -r - 3), width: 18, height: 8));
        canvas.drawPath(leafPath, Paint()..color = const Color(0xFF16A34A));
        break;

      case 'apple':
        final bodyPaint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.25, -0.25),
            radius: 0.9,
            colors: const [Color(0xFFFCA5A5), Color(0xFFEF4444), Color(0xFFDC2626), Color(0xFF7F1D1D)],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));

        final applePath = Path();
        applePath.moveTo(0, -r * 0.7);
        applePath.cubicTo(r * 0.65, -r * 1.05, r * 1.15, -r * 0.3, r * 0.95, r * 0.4);
        applePath.cubicTo(r * 0.75, r * 1.05, r * 0.2, r * 1.05, 0, r * 0.85);
        applePath.cubicTo(-r * 0.2, r * 1.05, -r * 0.75, r * 1.05, -r * 0.95, r * 0.4);
        applePath.cubicTo(-r * 1.15, -r * 0.3, -r * 0.65, -r * 1.05, 0, -r * 0.7);
        canvas.drawPath(applePath, bodyPaint);

        // Apple stem
        final stemPaint = Paint()
          ..color = const Color(0xFF59371D)
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        final appleStem = Path()..moveTo(0, -r * 0.65)..quadraticBezierTo(6, -r * 1.05, 10, -r * 1.15);
        canvas.drawPath(appleStem, stemPaint);
        break;

      case 'strawberry':
        final bodyPaint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.2, -0.2),
            radius: 0.9,
            colors: const [Color(0xFFFDA4AF), Color(0xFFF43F5E), Color(0xFFE11D48), Color(0xFF881337)],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));

        final berryPath = Path();
        berryPath.moveTo(0, -r * 0.7);
        berryPath.cubicTo(r * 0.85, -r * 0.7, r * 1.0, 0, 0, r * 1.05);
        berryPath.cubicTo(-r * 1.0, 0, -r * 0.85, -r * 0.7, 0, -r * 0.7);
        canvas.drawPath(berryPath, bodyPaint);

        // Golden seeds
        final seedPaint = Paint()..color = const Color(0xFFFEF08A);
        for (final offset in [
          Offset(0, -r * 0.3),
          Offset(-r * 0.35, -r * 0.25),
          Offset(r * 0.35, -r * 0.25),
          Offset(-r * 0.4, 0.0),
          Offset(0, 0.0),
          Offset(r * 0.4, 0.0),
          Offset(-r * 0.25, r * 0.3),
          Offset(r * 0.25, r * 0.3),
          Offset(0, r * 0.6),
        ]) {
          canvas.drawOval(Rect.fromCenter(center: offset, width: 3.5, height: 5), seedPaint);
        }

        // Green calyx leaves
        final leafPaint = Paint()..color = const Color(0xFF16A34A);
        for (double a in [-0.8, -0.4, 0.0, 0.4, 0.8]) {
          canvas.save();
          canvas.translate(0, -r * 0.65);
          canvas.rotate(a);
          final p = Path()..moveTo(0, 0)..lineTo(4, -13)..lineTo(-4, -13)..close();
          canvas.drawPath(p, leafPaint);
          canvas.restore();
        }
        break;

      case 'banana':
        final bodyPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const [Color(0xFFFEF08A), Color(0xFFFACC15), Color(0xFFCA8A04)],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));

        final bPath = Path();
        bPath.moveTo(-r * 0.85, -r * 0.65);
        bPath.cubicTo(-r * 0.4, -r * 0.1, -r * 0.2, r * 0.5, r * 0.85, r * 0.75);
        bPath.cubicTo(r * 0.2, r * 0.7, -r * 0.2, r * 0.1, -r * 0.85, -r * 0.65);
        canvas.drawPath(bPath, bodyPaint);

        canvas.drawOval(Rect.fromCenter(center: Offset(-r * 0.85, -r * 0.65), width: 8, height: 6), Paint()..color = const Color(0xFF4D7C0F));
        canvas.drawOval(Rect.fromCenter(center: Offset(r * 0.85, r * 0.75), width: 7, height: 5), Paint()..color = const Color(0xFF451A03));
        break;

      case 'pineapple':
        // Green crown
        final pCrown = Paint()..color = const Color(0xFF15803D);
        for (double a in [-0.5, -0.25, 0.0, 0.25, 0.5]) {
          canvas.save();
          canvas.translate(0, -r * 0.4);
          canvas.rotate(a);
          final p = Path()..moveTo(0, 0)..lineTo(6, -24)..lineTo(0, -30)..lineTo(-6, -24)..close();
          canvas.drawPath(p, pCrown);
          canvas.restore();
        }

        final bodyPaint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.2, 0.0),
            radius: 0.9,
            colors: const [Color(0xFFFEF08A), Color(0xFFFACC15), Color(0xFFCA8A04), Color(0xFF78350F)],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
        canvas.drawOval(Rect.fromCenter(center: Offset(0, r * 0.15), width: r * 1.5, height: r * 1.7), bodyPaint);
        break;

      case 'kiwi':
        final bodyPaint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.3),
            radius: 0.9,
            colors: const [Color(0xFFB45309), Color(0xFF78350F), Color(0xFF451A03)],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 1.7, height: r * 2.0), bodyPaint);
        break;

      case 'coconut':
        final bodyPaint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.3),
            radius: 0.9,
            colors: const [Color(0xFF78350F), Color(0xFF451A03), Color(0xFF270E02)],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
        canvas.drawCircle(Offset.zero, r, bodyPaint);

        // 3 eyes
        final eyePaint = Paint()..color = const Color(0xFF1C0A02);
        canvas.drawCircle(Offset(-7, -r * 0.35), 4, eyePaint);
        canvas.drawCircle(Offset(7, -r * 0.35), 4, eyePaint);
        canvas.drawCircle(Offset(0, -r * 0.18), 4.5, eyePaint);
        break;

      case 'bomb':
      default:
        // Iron bomb body
        final bombPaint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.35),
            radius: 0.9,
            colors: const [Color(0xFF94A3B8), Color(0xFF334155), Color(0xFF1E293B), Color(0xFF020617)],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
        canvas.drawCircle(Offset.zero, r, bombPaint);

        // Collar
        canvas.drawRect(Rect.fromLTWH(-7, -r - 5, 14, 6), Paint()..color = const Color(0xFFB45309));

        // Burning Fuse
        final fusePaint = Paint()
          ..color = const Color(0xFF78350F)
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        final fusePath = Path()..moveTo(0, -r - 5)..quadraticBezierTo(12, -r - 18, 16, -r - 22);
        canvas.drawPath(fusePath, fusePaint);

        // Spark at tip
        canvas.drawCircle(Offset(16, -r - 22), 4, Paint()..color = const Color(0xFFFBBF24));
        canvas.drawCircle(Offset(16, -r - 22), 2, Paint()..color = Colors.white);
        break;
    }

    // Glossy light reflection
    final glossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r * 0.75),
      -pi * 0.75,
      pi * 0.3,
      false,
      glossPaint,
    );
  }

  // --- DRAW SLICED FRUIT HALF ---
  void _drawSlicedFruitHalf(Canvas canvas, String fruitType, double r, bool isLeft, double opacity) {
    final startAng = isLeft ? pi * 0.5 : -pi * 0.5;
    final sweepAng = pi;

    switch (fruitType) {
      case 'watermelon':
        // Green outer rind
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r), startAng, sweepAng, true, Paint()..color = const Color(0xFF15803D).withValues(alpha: opacity.clamp(0.0, 1.0)));
        // White inner rind
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 0.88), startAng, sweepAng, true, Paint()..color = const Color(0xFFDCFCE7).withValues(alpha: opacity.clamp(0.0, 1.0)));
        // Red juicy flesh
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 0.8), startAng, sweepAng, true, Paint()..color = const Color(0xFFEF4444).withValues(alpha: opacity.clamp(0.0, 1.0)));

        // Seeds
        final seedPaint = Paint()..color = const Color(0xFF0F172A).withValues(alpha: opacity.clamp(0.0, 1.0));
        final sx = isLeft ? -r * 0.45 : r * 0.45;
        for (final sy in [-r * 0.35, 0.0, r * 0.35]) {
          canvas.drawOval(Rect.fromCenter(center: Offset(sx, sy), width: 5, height: 8), seedPaint);
        }
        break;

      case 'orange':
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r), startAng, sweepAng, true, Paint()..color = const Color(0xFFEA580C).withValues(alpha: opacity.clamp(0.0, 1.0)));
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 0.9), startAng, sweepAng, true, Paint()..color = const Color(0xFFFEF9C3).withValues(alpha: opacity.clamp(0.0, 1.0)));
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 0.82), startAng, sweepAng, true, Paint()..color = const Color(0xFFFB923C).withValues(alpha: opacity.clamp(0.0, 1.0)));
        break;

      case 'apple':
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r), startAng, sweepAng, true, Paint()..color = const Color(0xFFDC2626).withValues(alpha: opacity.clamp(0.0, 1.0)));
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 0.9), startAng, sweepAng, true, Paint()..color = const Color(0xFFFEF9C3).withValues(alpha: opacity.clamp(0.0, 1.0)));
        // Core seeds
        canvas.drawOval(Rect.fromCenter(center: Offset(isLeft ? -r * 0.25 : r * 0.25, 0), width: 6, height: 10), Paint()..color = const Color(0xFF451A03).withValues(alpha: opacity.clamp(0.0, 1.0)));
        break;

      case 'strawberry':
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r), startAng, sweepAng, true, Paint()..color = const Color(0xFFE11D48).withValues(alpha: opacity.clamp(0.0, 1.0)));
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 0.85), startAng, sweepAng, true, Paint()..color = const Color(0xFFFFE4E6).withValues(alpha: opacity.clamp(0.0, 1.0)));
        break;

      case 'kiwi':
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r), startAng, sweepAng, true, Paint()..color = const Color(0xFF78350F).withValues(alpha: opacity.clamp(0.0, 1.0)));
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 0.88), startAng, sweepAng, true, Paint()..color = const Color(0xFF22C55E).withValues(alpha: opacity.clamp(0.0, 1.0)));
        canvas.drawOval(Rect.fromCenter(center: Offset(isLeft ? -r * 0.2 : r * 0.2, 0), width: r * 0.4, height: r * 0.6), Paint()..color = const Color(0xFFFEF9C3).withValues(alpha: opacity.clamp(0.0, 1.0)));
        break;

      case 'coconut':
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r), startAng, sweepAng, true, Paint()..color = const Color(0xFF451A03).withValues(alpha: opacity.clamp(0.0, 1.0)));
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 0.85), startAng, sweepAng, true, Paint()..color = const Color(0xFFF8FAFC).withValues(alpha: opacity.clamp(0.0, 1.0)));
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 0.5), startAng, sweepAng, true, Paint()..color = const Color(0xFF1E1B4B).withValues(alpha: opacity.clamp(0.0, 1.0)));
        break;

      case 'bomb':
      default:
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r), startAng, sweepAng, true, Paint()..color = const Color(0xFF1E293B).withValues(alpha: opacity.clamp(0.0, 1.0)));
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 0.8), startAng, sweepAng, true, Paint()..color = const Color(0xFFEF4444).withValues(alpha: opacity.clamp(0.0, 1.0)));
        break;
    }
  }

  // --- DRAW WOODEN WORD BANNER ---
  void _drawWordBanner(Canvas canvas, String text, double r, bool isBomb) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();

    final bannerW = (tp.width + 24).clamp(76.0, 140.0);
    const bannerH = 25.0;
    final bannerRect = Rect.fromCenter(center: Offset.zero, width: bannerW, height: bannerH);

    // Plaque background
    final bgPaint = Paint()
      ..color = isBomb ? const Color(0xFF7F1D1D).withValues(alpha: 0.95) : const Color(0xFF1E140C).withValues(alpha: 0.92);
    canvas.drawRRect(RRect.fromRectAndRadius(bannerRect, const Radius.circular(8)), bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = isBomb ? const Color(0xFFF87171) : const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawRRect(RRect.fromRectAndRadius(bannerRect, const Radius.circular(8)), borderPaint);

    // Corner rivets
    final rivetPaint = Paint()..color = isBomb ? const Color(0xFFEF4444) : const Color(0xFFFBBF24);
    final rx = bannerW / 2 - 4.5;
    final ry = bannerH / 2 - 4.5;
    canvas.drawCircle(Offset(-rx, -ry), 1.8, rivetPaint);
    canvas.drawCircle(Offset(rx, -ry), 1.8, rivetPaint);
    canvas.drawCircle(Offset(-rx, ry), 1.8, rivetPaint);
    canvas.drawCircle(Offset(rx, ry), 1.8, rivetPaint);

    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }

  // --- DRAW SLICED HALF BANNER ---
  void _drawSlicedBanner(Canvas canvas, String text, bool isLeft, double opacity) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0)),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();

    const tagW = 38.0;
    const tagH = 22.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(isLeft ? -tagW : 0, -tagH / 2, tagW, tagH),
      const Radius.circular(4),
    );

    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF1E140C).withValues(alpha: opacity.clamp(0.0, 1.0)));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFFF59E0B).withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    tp.paint(canvas, Offset(isLeft ? -tagW / 2 - tp.width / 2 : tagW / 2 - tp.width / 2, -tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _NinjaArenaPainter oldDelegate) => true;
}
