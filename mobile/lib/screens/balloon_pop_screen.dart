import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/game_service.dart';
import '../data/game_question_bank.dart';
import '../services/game_audio_service.dart';

class BalloonPopScreen extends StatefulWidget {
  final String title;

  const BalloonPopScreen({
    super.key,
    this.title = 'Balloon Pop: Nature & Weather Words',
  });

  @override
  State<BalloonPopScreen> createState() => _BalloonPopScreenState();
}

class _BalloonItem {
  final int id;
  final String text;
  final bool isTarget;
  final Color color;
  final double radius;
  double x;
  double y;
  double vy;
  double wobbleAngle;
  double wobbleSpeed;
  bool popped = false;

  _BalloonItem({
    required this.id,
    required this.text,
    required this.isTarget,
    required this.color,
    required this.radius,
    required this.x,
    required this.y,
    required this.vy,
    required this.wobbleAngle,
    required this.wobbleSpeed,
  });
}

class _ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double size;
  double life;
  double maxLife;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.life,
    required this.maxLife,
  });
}

class _BalloonMission {
  final String title;
  final String prompt;
  final List<String> targets;
  final List<String> distractors;

  _BalloonMission({
    required this.title,
    required this.prompt,
    required this.targets,
    required this.distractors,
  });
}

class _BalloonPopScreenState extends State<BalloonPopScreen> {
  int _score = 0;
  int _lives = 5;
  int _currentMissionIndex = 0;
  int _missionPops = 0;
  final int _popsPerMission = 3; // 3 per mission, 5 missions = 15 total
  String _gameState = 'playing'; // 'playing', 'victory', 'gameover'
  bool _soundEnabled = true;

  Timer? _loopTimer;
  double _spawnTimer = 0.4;
  int _idCounter = 0;

  final List<_BalloonItem> _balloons = [];
  final List<_ConfettiParticle> _confetti = [];

  final List<_BalloonMission> _missions = [];

  final List<Color> _balloonPalette = [
    const Color(0xFFEF4444), // Crimson
    const Color(0xFF3B82F6), // Azure
    const Color(0xFF10B981), // Emerald
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
  ];

  @override
  void initState() {
    super.initState();
    _startBalloonGame();
  }

  @override
  void dispose() {
    _recordResult();
    _loopTimer?.cancel();
    super.dispose();
  }

  void _recordResult() {
    if (_score <= 0) return;
    GameService.recordActivity('balloon_pop', score: _score.clamp(1, 100));
  }

  void _startBalloonGame() {
    _recordResult();
    _score = 0;
    _lives = 5;
    _currentMissionIndex = 0;
    _missionPops = 0;
    _gameState = 'playing';
    _balloons.clear();
    _confetti.clear();
    _spawnTimer = 0.3;

    _missions.clear();
    final randomMissions = GameQuestionBank.getRandomBalloonMissions(5);
    for (int i = 0; i < randomMissions.length; i++) {
      final m = randomMissions[i];
      final titleStr = m['title'].toString().replaceFirst('Mission: ', '');
      _missions.add(_BalloonMission(
        title: titleStr,
        prompt: m['prompt'] as String,
        targets: List<String>.from(m['targets'] as List),
        distractors: List<String>.from(m['distractors'] as List),
      ));
    }

    _loopTimer?.cancel();
    _loopTimer = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick(0.016));
  }

  void _tick(double dt) {
    if (_gameState != 'playing') return;

    final random = Random();

    // 1. Spawning
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _spawnTimer = 1.0 + random.nextDouble() * 0.5;
      _launchBalloon();
    }

    // 2. Update Balloons (Rising Upwards)
    for (int i = _balloons.length - 1; i >= 0; i--) {
      final b = _balloons[i];
      b.y -= b.vy * dt;
      b.wobbleAngle += b.wobbleSpeed * dt;
      b.x += sin(b.wobbleAngle) * 0.8;

      // Escaped from top of screen!
      if (b.y < -60) {
        if (b.isTarget && !b.popped) {
          // Missed target balloon!
          _lives--;
          if (_lives <= 0) _gameState = 'gameover';
        }
        _balloons.removeAt(i);
      }
    }

    // 3. Update Confetti
    for (int i = _confetti.length - 1; i >= 0; i--) {
      final c = _confetti[i];
      c.x += c.vx * dt;
      c.y += c.vy * dt;
      c.vy += 220 * dt; // gravity on confetti
      c.life -= dt;
      if (c.life <= 0) _confetti.removeAt(i);
    }

    if (mounted) setState(() {});
  }

  void _launchBalloon() {
    final random = Random();
    final currentM = _missions[_currentMissionIndex];
    final isTarget = random.nextDouble() < 0.65;
    final text = isTarget
        ? currentM.targets[random.nextInt(currentM.targets.length)]
        : currentM.distractors[random.nextInt(currentM.distractors.length)];

    final color = _balloonPalette[random.nextInt(_balloonPalette.length)];
    final spawnX = 50.0 + random.nextDouble() * 240.0;
    final speed = 85.0 + random.nextDouble() * 55.0;

    _balloons.add(_BalloonItem(
      id: ++_idCounter,
      text: text,
      isTarget: isTarget,
      color: color,
      radius: 36,
      x: spawnX,
      y: 530,
      vy: speed,
      wobbleAngle: random.nextDouble() * pi * 2,
      wobbleSpeed: 2.0 + random.nextDouble() * 2.0,
    ));
  }

  void _popBalloonAt(Offset touch) {
    if (_gameState != 'playing') return;

    for (int i = _balloons.length - 1; i >= 0; i--) {
      final b = _balloons[i];
      if (b.popped) continue;

      final dist = (touch - Offset(b.x, b.y)).distance;
      if (dist <= b.radius + 12) {
        _popBalloon(b);
        break;
      }
    }
  }

  void _popBalloon(_BalloonItem b) {
    b.popped = true;
    GameAudioService.playBalloonPop();

    if (b.isTarget) {
      // CORRECT!
      GameAudioService.playCorrectDing();
      _missionPops++;
      _score += 100;
      _addConfetti(b.x, b.y, b.color, 28);

      if (_missionPops >= _popsPerMission) {
        if (_currentMissionIndex < _missions.length - 1) {
          _currentMissionIndex++;
          _missionPops = 0;
          _balloons.clear();
        } else {
          GameAudioService.playVictoryFanfare();
          _gameState = 'victory';
        }
      }
    } else {
      // WRONG!
      GameAudioService.playWrongBuzz();
      _lives--;
      _addConfetti(b.x, b.y, const Color(0xFFEF4444), 32);

      if (_lives <= 0) {
        _gameState = 'gameover';
      }
    }
  }

  void _addConfetti(double x, double y, Color color, int count) {
    final random = Random();
    for (int i = 0; i < count; i++) {
      final angle = random.nextDouble() * pi * 2;
      final speed = 60.0 + random.nextDouble() * 180.0;
      _confetti.add(_ConfettiParticle(
        x: x,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 60,
        color: random.nextBool() ? color : Colors.white,
        size: 3.0 + random.nextDouble() * 4.0,
        life: 0.5 + random.nextDouble() * 0.3,
        maxLife: 0.8,
      ));
    }
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
                  // 1. ☁️ Real Cloud Realm / Sky Background
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/bg_option3_cloud_kingdom.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF0F172A)),
                    ),
                  ),

                  // 2. Atmospheric Dark Vignette Gradient for High Contrast
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
                      // Top HUD
                      _buildTopHud(),

                      // Mission Objective
                      _buildObjectiveBanner(),

                      // Balloon Sky Arena
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanDown: (details) => _popBalloonAt(details.localPosition),
                          onPanUpdate: (details) => _popBalloonAt(details.localPosition),
                          child: CustomPaint(
                            painter: _BalloonSkyPainter(
                              balloons: _balloons,
                              confetti: _confetti,
                            ),
                            child: Container(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Overlays
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
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'MISSION ${_currentMissionIndex + 1}/${_missions.length}',
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
    final currentM = _missions[_currentMissionIndex];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0F172A).withValues(alpha: 0.92),
            const Color(0xFF1E293B).withValues(alpha: 0.88),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
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
              color: const Color(0xFF0284C7).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bubble_chart_rounded, color: Color(0xFF38BDF8), size: 13),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'MISSION ${_currentMissionIndex + 1}/5: ${currentM.title.toUpperCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
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
            currentM.prompt,
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
              const Icon(Icons.celebration_rounded, color: Color(0xFFF59E0B), size: 64),
              const SizedBox(height: 12),
              const Text(
                '🎉 CLEAR SKIES AHEAD!',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'All target balloons popped perfectly!',
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
                onPressed: _startBalloonGame,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Play Again', style: TextStyle(fontWeight: FontWeight.bold)),
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
              const Icon(Icons.cloud_off_rounded, color: Color(0xFFEF4444), size: 64),
              const SizedBox(height: 12),
              const Text(
                'OUT OF LIVES!',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Avoid popping wrong objects and don\'t let nature words escape!',
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
                onPressed: _startBalloonGame,
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

// --- CANVAS PAINTER (BALLOONS & STRINGS & CONFETTI) ---
class _BalloonSkyPainter extends CustomPainter {
  final List<_BalloonItem> balloons;
  final List<_ConfettiParticle> confetti;

  _BalloonSkyPainter({required this.balloons, required this.confetti});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Confetti Particles
    for (final c in confetti) {
      final pPaint = Paint()
        ..color = c.color.withValues(alpha: (c.life / c.maxLife).clamp(0.0, 1.0));
      canvas.drawRect(Rect.fromLTWH(c.x, c.y, c.size, c.size * 1.5), pPaint);
    }

    // 3. Floating Balloons
    for (final b in balloons) {
      if (b.popped) continue;

      canvas.save();
      canvas.translate(b.x, b.y);

      // String (Wobbly line dangling down)
      final stringPaint = Paint()
        ..color = Colors.white54
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      final stringPath = Path()
        ..moveTo(0, b.radius * 1.1)
        ..quadraticBezierTo(sin(b.wobbleAngle) * 8, b.radius * 1.6, 0, b.radius * 2.2);
      canvas.drawPath(stringPath, stringPaint);

      // Balloon Knot
      final knotPaint = Paint()..color = b.color;
      canvas.drawCircle(Offset(0, b.radius * 1.1), 3.5, knotPaint);

      // Balloon Shadow
      final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.3);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 4), width: b.radius * 2.2, height: b.radius * 2.6),
        shadowPaint,
      );

      // Balloon Body (Oval gradient)
      final bodyRect = Rect.fromCenter(center: Offset.zero, width: b.radius * 2.2, height: b.radius * 2.6);
      final bodyPaint = Paint()
        ..shader = RadialGradient(
          colors: [b.color.withValues(alpha: 0.95), b.color],
          center: const Alignment(-0.3, -0.3),
        ).createShader(bodyRect);
      canvas.drawOval(bodyRect, bodyPaint);

      // Highlight sheen (glossy curve on upper-left)
      final sheenPaint = Paint()..color = Colors.white.withValues(alpha: 0.45);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(-b.radius * 0.45, -b.radius * 0.5), width: b.radius * 0.5, height: b.radius * 0.7),
        sheenPaint,
      );

      // Balloon Text
      final tp = TextPainter(
        text: TextSpan(
          text: b.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black87, blurRadius: 4),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BalloonSkyPainter oldDelegate) => true;
}
