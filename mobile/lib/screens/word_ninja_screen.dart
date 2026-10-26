import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

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
  int _lives = 3;
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

  // 5 Distinct Language Challenges (Matching user's request for 5 questions in Ninja)
  final List<_NinjaChallenge> _challenges = [
    _NinjaChallenge(
      title: 'Challenge 1/5: Adjectives',
      prompt: 'Slice only ADJECTIVES! (Avoid verbs & nouns)',
      targets: ['Enormous', 'Silent', 'Brilliant', 'Gentle', 'Fierce', 'Sparkling'],
      distractors: ['Running', 'Building', 'Elephant', 'Tree', 'Sleep'],
    ),
    _NinjaChallenge(
      title: 'Challenge 2/5: Action Verbs',
      prompt: 'Slice only ACTION VERBS! (Avoid objects & nouns)',
      targets: ['Sprint', 'Leap', 'Climb', 'Roar', 'Dance', 'Swim'],
      distractors: ['Castle', 'Table', 'Guitar', 'Window', 'Chair'],
    ),
    _NinjaChallenge(
      title: 'Challenge 3/5: Plural Nouns',
      prompt: 'Slice only PLURAL NOUNS! (Irregular plurals)',
      targets: ['Children', 'Wolves', 'People', 'Teeth', 'Leaves', 'Mice'],
      distractors: ['Child', 'Wolf', 'Person', 'Tooth', 'Leaf', 'Mouse'],
    ),
    _NinjaChallenge(
      title: 'Challenge 4/5: Adverbs',
      prompt: 'Slice only ADVERBS! (Words telling HOW)',
      targets: ['Quickly', 'Silently', 'Happily', 'Bravely', 'Softly', 'Calmly'],
      distractors: ['Quick', 'Silent', 'Happy', 'Brave', 'Soft', 'Calm'],
    ),
    _NinjaChallenge(
      title: 'Challenge 5/5: Synonyms of "Happy"',
      prompt: 'Slice only SYNONYMS of "Happy"!',
      targets: ['Joyful', 'Cheerful', 'Delighted', 'Glad', 'Ecstatic', 'Merry'],
      distractors: ['Angry', 'Sad', 'Gloomy', 'Tired', 'Heavy', 'Bored'],
    ),
  ];

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
    _lives = 3;
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

    for (int i = 0; i < count; i++) {
      final isTarget = random.nextDouble() < 0.65;
      final text = isTarget
          ? currentCh.targets[random.nextInt(currentCh.targets.length)]
          : currentCh.distractors[random.nextInt(currentCh.distractors.length)];

      final spawnX = 60.0 + random.nextDouble() * 220.0;
      final spawnY = 540.0;
      final vx = (random.nextDouble() - 0.5) * 120.0;
      final vy = -460.0 - random.nextDouble() * 90.0;

      _items.add(_NinjaItem(
        id: ++_idCounter,
        text: text,
        isTarget: isTarget,
        color: isTarget ? const Color(0xFF10B981) : const Color(0xFFEF4444),
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

    if (item.isTarget) {
      // SUCCESS SLICE
      _challengeSlices++;
      _streak++;
      final bonus = 100 + (_streak >= 2 ? _streak * 20 : 0);
      _score += bonus;

      // Slice pieces
      final mid = (item.text.length / 2).ceil();
      final leftText = item.text.substring(0, mid);
      final rightText = item.text.substring(mid);

      _pieces.add(_SlicePiece(
        text: leftText,
        color: item.color,
        radius: item.radius * 0.8,
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
        radius: item.radius * 0.8,
        x: item.x + 14,
        y: item.y,
        vx: item.vx + 70,
        vy: item.vy - 40,
        angle: item.angle,
        vRot: 3.5,
      ));

      // Juice Splatter
      _addSplatter(item.x, item.y, const Color(0xFF10B981), 24);

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
            text: 'ROUND $_currentChallengeIndex CLEARED! 🌟',
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
      _streak = 0;
      _lives--;
      _addSplatter(item.x, item.y, const Color(0xFFEF4444), 32);

      _feedbacks.add(_FloatingFeedback(
        text: 'WRONG! -1 ❤️',
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
              const SizedBox(width: 6),
              Text(
                '$_score',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (_streak >= 2) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Text(
                    '⚡ ${_streak}x Combo',
                    style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          Text(
            'CHALLENGE ${_currentChallengeIndex + 1}/${_challenges.length}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 0.8,
            ),
          ),
          Row(
            children: [
              ...List.generate(
                3,
                (i) => Icon(
                  i < _lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: i < _lives ? const Color(0xFFEF4444) : Colors.white24,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _soundEnabled = !_soundEnabled),
                child: Icon(
                  _soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: Colors.white70,
                  size: 18,
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
      color: const Color(0xFF0D1B2A),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.content_cut_rounded, color: Color(0xFFF59E0B), size: 14),
              const SizedBox(width: 6),
              Text(
                'CHALLENGE ${_currentChallengeIndex + 1}/5: ${currentCh.title.toUpperCase()}',
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            currentCh.prompt,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
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

// --- CANVAS PAINTER (BALLOONS / ORBS / KATANA SLASH TRAIL) ---
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
    // 1. Dojo Arena Background
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
        radius: 0.9,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Dojo Faint Grid Lines
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1.0;
    for (double y = 40; y < size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // 2. Juice Particles
    for (final pt in particles) {
      final pPaint = Paint()
        ..color = pt.color.withValues(alpha: (pt.life / pt.maxLife).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(pt.x, pt.y), pt.radius, pPaint);
    }

    // 3. Floating Unsliced Word Bubbles / Balloons
    for (final item in items) {
      if (item.sliced) continue;

      canvas.save();
      canvas.translate(item.x, item.y);
      canvas.rotate(item.angle);

      // Shadow
      final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.35);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(0, 5), width: item.radius * 2.3, height: item.radius * 1.3),
          const Radius.circular(24),
        ),
        shadowPaint,
      );

      // Body Gradient (Balloon / Pill shape)
      final bodyRect = Rect.fromCenter(center: Offset.zero, width: item.radius * 2.3, height: item.radius * 1.3);
      final bodyPaint = Paint()
        ..shader = LinearGradient(
          colors: item.isTarget
              ? [const Color(0xFF34D399), const Color(0xFF059669)]
              : [const Color(0xFFF87171), const Color(0xFFDC2626)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bodyRect);

      canvas.drawRRect(
        RRect.fromRectAndRadius(bodyRect, const Radius.circular(24)),
        bodyPaint,
      );

      // Glossy Highlight
      final highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.35);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-item.radius * 0.9, -item.radius * 0.5, item.radius * 1.8, item.radius * 0.35),
          const Radius.circular(12),
        ),
        highlightPaint,
      );

      // Neon Border
      final borderPaint = Paint()
        ..color = item.isTarget ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(bodyRect, const Radius.circular(24)),
        borderPaint,
      );

      // Word Text
      final textPainter = TextPainter(
        text: TextSpan(
          text: item.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));

      canvas.restore();
    }

    // 4. Sliced Pieces (Falling Apart in 2 halves)
    for (final p in pieces) {
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.angle);

      final piecePaint = Paint()
        ..color = p.color.withValues(alpha: p.opacity.clamp(0.0, 1.0));
      final pieceRect = Rect.fromCenter(center: Offset.zero, width: p.radius * 1.4, height: p.radius * 1.1);
      canvas.drawRRect(RRect.fromRectAndRadius(pieceRect, const Radius.circular(12)), piecePaint);

      final tp = TextPainter(
        text: TextSpan(
          text: p.text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: p.opacity.clamp(0.0, 1.0)),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));

      canvas.restore();
    }

    // 5. Floating Feedbacks
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

    // 6. Katana Slash Blade Trail (Glowing razor trail)
    if (bladeTrail.length >= 2) {
      for (int i = 0; i < bladeTrail.length - 1; i++) {
        final p1 = bladeTrail[i];
        final p2 = bladeTrail[i + 1];
        final progress = (i + 1) / bladeTrail.length;

        // Outer glow
        final glowPaint = Paint()
          ..color = const Color(0xFF38BDF8).withValues(alpha: progress * 0.7)
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

  @override
  bool shouldRepaint(covariant _NinjaArenaPainter oldDelegate) => true;
}
