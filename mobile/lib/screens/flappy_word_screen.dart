import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class FlappyWordScreen extends StatefulWidget {
  final String title;

  const FlappyWordScreen({
    super.key,
    this.title = 'Flappy Word: Irregular Verb Skyways',
  });

  @override
  State<FlappyWordScreen> createState() => _FlappyWordScreenState();
}

class _CloudGateWave {
  final String question;
  final String topText;
  final bool topCorrect;
  final String bottomText;
  final bool bottomCorrect;

  _CloudGateWave({
    required this.question,
    required this.topText,
    required this.topCorrect,
    required this.bottomText,
    required this.bottomCorrect,
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

class _BgCloud {
  double x;
  double y;
  double size;
  double speed;

  _BgCloud({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
}

class _FlappyWordScreenState extends State<FlappyWordScreen> {
  int _score = 0;
  int _lives = 3;
  int _currentWaveIndex = 0;
  String _gameState = 'playing'; // 'playing', 'victory', 'gameover'
  bool _soundEnabled = true;

  // Bird Physics
  final double _birdX = 85.0;
  double _birdY = 240.0;
  double _birdVy = 0.0;
  double _birdAngle = 0.0;
  final double _gravity = 640.0;
  final double _flapStrength = -250.0;

  // Cloud Gates
  double _gateX = 420.0;
  final double _gateSpeed = 150.0;
  bool _gatePassed = false;
  String? _feedbackText;
  Color? _feedbackColor;

  Timer? _loopTimer;
  final List<_Particle> _particles = [];
  final List<_BgCloud> _bgClouds = [];

  final List<_CloudGateWave> _waves = [
    _CloudGateWave(
      question: "Fly to the Past Tense of 'Sing':",
      topText: 'Sang',
      topCorrect: true,
      bottomText: 'Singed',
      bottomCorrect: false,
    ),
    _CloudGateWave(
      question: "Fly to the Past Tense of 'Write':",
      topText: 'Writed',
      topCorrect: false,
      bottomText: 'Wrote',
      bottomCorrect: true,
    ),
    _CloudGateWave(
      question: "Fly to the Past Tense of 'Fly':",
      topText: 'Flew',
      topCorrect: true,
      bottomText: 'Flied',
      bottomCorrect: false,
    ),
    _CloudGateWave(
      question: "Fly to the Past Tense of 'Swim':",
      topText: 'Swam',
      topCorrect: true,
      bottomText: 'Swum',
      bottomCorrect: false,
    ),
    _CloudGateWave(
      question: "Fly to the Past Tense of 'Catch':",
      topText: 'Catched',
      topCorrect: false,
      bottomText: 'Caught',
      bottomCorrect: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initBgClouds();
    _startFlappyGame();
  }

  @override
  void dispose() {
    _loopTimer?.cancel();
    super.dispose();
  }

  void _initBgClouds() {
    final random = Random();
    _bgClouds.clear();
    for (int i = 0; i < 5; i++) {
      _bgClouds.add(_BgCloud(
        x: random.nextDouble() * 360,
        y: 40 + random.nextDouble() * 220,
        size: 26 + random.nextDouble() * 20,
        speed: 20 + random.nextDouble() * 30,
      ));
    }
  }

  void _startFlappyGame() {
    _score = 0;
    _lives = 3;
    _currentWaveIndex = 0;
    _gameState = 'playing';
    _birdY = 240.0;
    _birdVy = 0.0;
    _birdAngle = 0.0;
    _gateX = 380.0;
    _gatePassed = false;
    _feedbackText = null;
    _particles.clear();

    _loopTimer?.cancel();
    _loopTimer = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick(0.016));
  }

  void _flap() {
    if (_gameState != 'playing') return;
    setState(() {
      _birdVy = _flapStrength;
      _birdAngle = -0.38;
      _addFeathers();
    });
  }

  void _addFeathers() {
    final random = Random();
    for (int i = 0; i < 3; i++) {
      _particles.add(_Particle(
        x: _birdX - 12,
        y: _birdY + (random.nextDouble() - 0.5) * 10,
        vx: -35 - random.nextDouble() * 30,
        vy: 20 + random.nextDouble() * 30,
        color: const Color(0xFFFEF08A),
        radius: 2.5,
        life: 0.35,
        maxLife: 0.35,
      ));
    }
  }

  void _addBurst(double x, double y, Color color) {
    final random = Random();
    for (int i = 0; i < 20; i++) {
      final angle = random.nextDouble() * pi * 2;
      final speed = 40.0 + random.nextDouble() * 140.0;
      _particles.add(_Particle(
        x: x,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        color: color,
        radius: 2.5 + random.nextDouble() * 3.5,
        life: 0.45,
        maxLife: 0.45,
      ));
    }
  }

  void _tick(double dt) {
    if (_gameState != 'playing') return;

    // 1. Bird Physics
    _birdVy += _gravity * dt;
    _birdY += _birdVy * dt;
    _birdAngle = (_birdAngle + 1.2 * dt).clamp(-0.4, 0.7);

    // Floor and Ceiling Collisions
    if (_birdY > 440) {
      _handleCrash('CRASHED TO GROUND! 💥');
      return;
    }
    if (_birdY < 20) {
      _birdY = 20;
      _birdVy = 0;
    }

    // 2. Background Clouds
    for (var c in _bgClouds) {
      c.x -= c.speed * dt;
      if (c.x < -80) c.x = 420;
    }

    // 3. Move Cloud Gates
    _gateX -= _gateSpeed * dt;

    // Gate Collision Check
    // Top Gate center Y: 130, Bottom Gate center Y: 330. Gate thickness: ~90px wide, ~80px tall
    final currentWave = _waves[_currentWaveIndex];
    if (!_gatePassed && (_gateX - _birdX).abs() < 55) {
      final inTopGate = (_birdY - 130).abs() < 52;
      final inBottomGate = (_birdY - 330).abs() < 52;

      if (inTopGate) {
        _gatePassed = true;
        _evaluateHit(currentWave.topCorrect, currentWave.topText);
      } else if (inBottomGate) {
        _gatePassed = true;
        _evaluateHit(currentWave.bottomCorrect, currentWave.bottomText);
      }
    }

    // Next Gate Reset
    if (_gateX < -120) {
      if (!_gatePassed) {
        // Missed both gates!
        _handleCrash('MISSED GATE! ⏱️');
      } else {
        _nextGate();
      }
    }

    // 4. Update Particles
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.life -= dt;
      if (p.life <= 0) _particles.removeAt(i);
    }

    if (mounted) setState(() {});
  }

  void _evaluateHit(bool isCorrect, String text) {
    if (isCorrect) {
      // SUCCESS!
      _score += 100;
      _feedbackText = 'CORRECT! "$text" +100 🎯';
      _feedbackColor = const Color(0xFF10B981);
      _addBurst(_birdX, _birdY, const Color(0xFF10B981));
    } else {
      // WRONG CLOUD!
      _lives--;
      _feedbackText = 'WRONG! "$text" -1 ❤️';
      _feedbackColor = const Color(0xFFEF4444);
      _addBurst(_birdX, _birdY, const Color(0xFFEF4444));

      if (_lives <= 0) {
        _gameState = 'gameover';
      }
    }
  }

  void _nextGate() {
    if (_currentWaveIndex < _waves.length - 1) {
      _currentWaveIndex++;
      _gateX = 380;
      _gatePassed = false;
      _feedbackText = null;
    } else {
      _gameState = 'victory';
    }
  }

  void _handleCrash(String reason) {
    _lives--;
    _feedbackText = reason;
    _feedbackColor = const Color(0xFFEF4444);
    _addBurst(_birdX, _birdY, const Color(0xFFEF4444));

    if (_lives <= 0) {
      _gameState = 'gameover';
    } else {
      // Reset bird position and move to next gate
      _birdY = 240;
      _birdVy = 0;
      _gateX = 380;
      _gatePassed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentWave = _waves[_currentWaveIndex];

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
                      // 1. TOP HUD BAR
                      _buildTopHud(),

                      // 2. TARGET OBJECTIVE BANNER
                      _buildObjectiveBanner(currentWave.question),

                      // 3. FLAPPY SKY ARENA
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (_) => _flap(),
                          child: Stack(
                            children: [
                              // Sky & Clouds & Bird Canvas
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _FlappyPainter(
                                    birdX: _birdX,
                                    birdY: _birdY,
                                    birdAngle: _birdAngle,
                                    gateX: _gateX,
                                    currentWave: currentWave,
                                    bgClouds: _bgClouds,
                                    particles: _particles,
                                  ),
                                ),
                              ),

                              // Floating Feedback Banner
                              if (_feedbackText != null)
                                Positioned(
                                  top: 16,
                                  left: 20,
                                  right: 20,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _feedbackColor?.withValues(alpha: 0.95),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: const [
                                          BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4)),
                                        ],
                                      ),
                                      child: Text(
                                        _feedbackText!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // 4. TOUCH FLAP CONTROL BUTTON BAR
                      _buildControlBar(),
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
            ],
          ),
          Text(
            'CLOUD GATE ${_currentWaveIndex + 1}/${_waves.length}',
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

  Widget _buildObjectiveBanner(String question) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0D1B2A),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flight_takeoff_rounded, color: Color(0xFF38BDF8), size: 14),
              SizedBox(width: 6),
              Text(
                'TARGET FLIGHT',
                style: TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            question,
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

  Widget _buildControlBar() {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _flap,
          icon: const Icon(Icons.flight_rounded, size: 24),
          label: const Text(
            'FLAP WINGS 🕊️ (Or Tap Screen)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 4,
          ),
        ),
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
              const Icon(Icons.wb_sunny_rounded, color: Color(0xFFF59E0B), size: 64),
              const SizedBox(height: 12),
              const Text(
                '🌤️ SKIES CLEARED!',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'You steered through every word cloud safely!',
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
                onPressed: _startFlappyGame,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Fly Again', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
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
                'FLIGHT LOST!',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'You ran out of flight shields. Avoid wrong word clouds!',
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
                onPressed: _startFlappyGame,
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

// --- FLAPPY SKY CANVAS PAINTER ---
class _FlappyPainter extends CustomPainter {
  final double birdX;
  final double birdY;
  final double birdAngle;
  final double gateX;
  final _CloudGateWave currentWave;
  final List<_BgCloud> bgClouds;
  final List<_Particle> particles;

  _FlappyPainter({
    required this.birdX,
    required this.birdY,
    required this.birdAngle,
    required this.gateX,
    required this.currentWave,
    required this.bgClouds,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Sky Gradient (Deep Sky to Horizon)
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0284C7), Color(0xFF38BDF8), Color(0xFFBAE6FD)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // 2. Background Floating Clouds
    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.45);
    for (var c in bgClouds) {
      canvas.drawCircle(Offset(c.x, c.y), c.size, cloudPaint);
      canvas.drawCircle(Offset(c.x + c.size * 0.6, c.y - c.size * 0.3), c.size * 0.7, cloudPaint);
      canvas.drawCircle(Offset(c.x + c.size * 1.2, c.y), c.size * 0.8, cloudPaint);
    }

    // 3. Cloud Gates (Top Cloud Gate Y: 130, Bottom Cloud Gate Y: 330)
    _drawCloudGate(canvas, gateX, 130, currentWave.topText, currentWave.topCorrect);
    _drawCloudGate(canvas, gateX, 330, currentWave.bottomText, currentWave.bottomCorrect);

    // 4. Ground (Green hills at bottom)
    final groundPaint = Paint()..color = const Color(0xFF15803D);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 24, size.width, 24), groundPaint);
    final grassTopPaint = Paint()..color = const Color(0xFF4ADE80);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 24, size.width, 5), grassTopPaint);

    // 5. Particles (Feathers & Bursts)
    for (var p in particles) {
      final pPaint = Paint()
        ..color = p.color.withValues(alpha: (p.life / p.maxLife).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(p.x, p.y), p.radius, pPaint);
    }

    // 6. Bird Sprite (Cute Yellow Aviator Bird)
    _drawBird(canvas, birdX, birdY, birdAngle);
  }

  void _drawCloudGate(Canvas canvas, double x, double y, String text, bool isCorrect) {
    canvas.save();
    canvas.translate(x, y);

    // Cloud shadow
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.15);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 4), width: 140, height: 74), const Radius.circular(22)),
      shadowPaint,
    );

    // Cloud body
    final bodyPaint = Paint()..color = Colors.white.withValues(alpha: 0.95);
    final borderPaint = Paint()
      ..color = isCorrect ? const Color(0xFF10B981) : const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final rrect = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 140, height: 74), const Radius.circular(22));
    canvas.drawRRect(rrect, bodyPaint);
    canvas.drawRRect(rrect, borderPaint);

    // Text Option
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));

    canvas.restore();
  }

  void _drawBird(Canvas canvas, double x, double y, double angle) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);

    // Bird Body (Bright Yellow)
    final bodyPaint = Paint()..color = const Color(0xFFFACC15);
    canvas.drawCircle(Offset.zero, 18, bodyPaint);

    // Wing
    final wingPaint = Paint()..color = const Color(0xFFEAB308);
    canvas.drawOval(Rect.fromCenter(center: const Offset(-6, 2), width: 18, height: 12), wingPaint);

    // Eye White
    canvas.drawCircle(const Offset(8, -5), 5.5, Paint()..color = Colors.white);
    // Pupil
    canvas.drawCircle(const Offset(10, -5), 2.8, Paint()..color = const Color(0xFF0F172A));

    // Beak (Orange)
    final beakPaint = Paint()..color = const Color(0xFFF97316);
    final path = Path()
      ..moveTo(14, -3)
      ..lineTo(24, 2)
      ..lineTo(14, 7)
      ..close();
    canvas.drawPath(path, beakPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FlappyPainter oldDelegate) => true;
}
