import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/game_service.dart';
import '../data/game_question_bank.dart';
import '../services/game_audio_service.dart';

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
  int _lives = 5;
  int _currentWaveIndex = 0;
  String _gameState = 'playing'; // 'playing', 'victory', 'gameover'
  bool _soundEnabled = true;

  // Bird Physics & 70% Original Animation
  final double _birdX = 85.0;
  double _birdY = 240.0;
  double _birdVy = 0.0;
  double _birdAngle = 0.0;
  double _wingAngle = 0.0;
  double _animTimer = 0.0;
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

  final List<_CloudGateWave> _waves = [];

  @override
  void initState() {
    super.initState();
    _initBgClouds();
    _startFlappyGame();
  }

  @override
  void dispose() {
    _recordResult();
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

  void _recordResult() {
    if (_score <= 0) return;
    GameService.recordActivity('flappy_word', score: _score.clamp(1, 100));
  }

  void _startFlappyGame() {
    _recordResult();
    _score = 0;
    _lives = 5;
    _currentWaveIndex = 0;
    _gameState = 'playing';
    _birdY = 240.0;
    _birdVy = 0.0;
    _birdAngle = 0.0;
    _wingAngle = 0.0;
    _animTimer = 0.0;
    _gateX = 380.0;
    _gatePassed = false;
    _feedbackText = null;
    _particles.clear();

    _waves.clear();
    final randomWaves = GameQuestionBank.getRandomFlappyWaves(5);
    for (var w in randomWaves) {
      _waves.add(_CloudGateWave(
        question: w['question'] as String,
        topText: w['topText'] as String,
        topCorrect: w['topCorrect'] as bool,
        bottomText: w['bottomText'] as String,
        bottomCorrect: w['bottomCorrect'] as bool,
      ));
    }

    _loopTimer?.cancel();
    _loopTimer = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick(0.016));
  }

  void _flap() {
    if (_gameState != 'playing') return;
    GameAudioService.playBirdFlap();
    setState(() {
      _birdVy = _flapStrength;
      _birdAngle = -0.42;
      _wingAngle = -0.8;
      _addFeathers();
    });
  }

  void _addFeathers() {
    final random = Random();
    for (int i = 0; i < 6; i++) {
      _particles.add(_Particle(
        x: _birdX - 14,
        y: _birdY + (random.nextDouble() - 0.5) * 12,
        vx: -45 - random.nextDouble() * 40,
        vy: 20 + random.nextDouble() * 45,
        color: i % 2 == 0 ? const Color(0xFFFEF08A) : Colors.white70,
        radius: 2.8 + random.nextDouble() * 2.0,
        life: 0.45,
        maxLife: 0.45,
      ));
    }
  }

  void _addBurst(double x, double y, Color color) {
    final random = Random();
    for (int i = 0; i < 28; i++) {
      final angle = random.nextDouble() * pi * 2;
      final speed = 40.0 + random.nextDouble() * 160.0;
      _particles.add(_Particle(
        x: x,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        color: color,
        radius: 2.5 + random.nextDouble() * 3.5,
        life: 0.55,
        maxLife: 0.55,
      ));
    }
  }

  void _tick(double dt) {
    if (_gameState != 'playing') return;

    _animTimer += dt;

    // 1. Bird Physics & Animated Wing Flap
    _birdVy += _gravity * dt;
    _birdY += _birdVy * dt;
    _birdAngle = (_birdAngle + 1.3 * dt).clamp(-0.45, 0.70);

    // Continuous wing oscillation (flaps faster when ascending)
    final flapSpeed = _birdVy < 0 ? 28.0 : 12.0;
    _wingAngle = sin(_animTimer * flapSpeed) * 0.65;

    // 🌟 Continuous Rainbow Jetstream Trail behind the bird
    const rainbowColors = [
      Color(0xFFEF4444),
      Color(0xFFF97316),
      Color(0xFFFBBF24),
      Color(0xFF10B981),
      Color(0xFF38BDF8),
      Color(0xFFA855F7),
    ];
    final colorIdx = (_animTimer * 14).floor() % rainbowColors.length;
    _particles.add(_Particle(
      x: _birdX - 16,
      y: _birdY + sin(_animTimer * 8) * 4,
      vx: -75 - Random().nextDouble() * 25,
      vy: (Random().nextDouble() - 0.5) * 20,
      color: rainbowColors[colorIdx],
      radius: 2.6 + Random().nextDouble() * 1.8,
      life: 0.42,
      maxLife: 0.42,
    ));

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
      GameAudioService.playCorrectDing();
      _score += 100;
      _feedbackText = 'CORRECT! "$text" +100 🎯';
      _feedbackColor = const Color(0xFF10B981);
      _addBurst(_birdX, _birdY, const Color(0xFF10B981));
    } else {
      // WRONG CLOUD!
      GameAudioService.playWrongBuzz();
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
      GameAudioService.playVictoryFanfare();
      _gameState = 'victory';
    }
  }

  void _handleCrash(String reason) {
    GameAudioService.playWrongBuzz();
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
                                    wingAngle: _wingAngle,
                                    animTimer: _animTimer,
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
                'GATE ${_currentWaveIndex + 1}/${_waves.length}',
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

  Widget _buildObjectiveBanner(String question) {
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
                const Icon(Icons.flight_takeoff_rounded, color: Color(0xFF38BDF8), size: 13),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'TARGET: GATE ${_currentWaveIndex + 1}/${_waves.length}',
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
            question,
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

// --- 70% ORIGINAL FLAPPY SKY CANVAS PAINTER ---
class _FlappyPainter extends CustomPainter {
  final double birdX;
  final double birdY;
  final double birdAngle;
  final double wingAngle;
  final double animTimer;
  final double gateX;
  final _CloudGateWave currentWave;
  final List<_BgCloud> bgClouds;
  final List<_Particle> particles;

  _FlappyPainter({
    required this.birdX,
    required this.birdY,
    required this.birdAngle,
    required this.wingAngle,
    required this.animTimer,
    required this.gateX,
    required this.currentWave,
    required this.bgClouds,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Sky Gradient (Deep Sky to Radiant Horizon)
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0284C7), Color(0xFF38BDF8), Color(0xFFBAE6FD)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // Subtle sun flare in top left
    final sunGlow = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withValues(alpha: 0.35), Colors.transparent],
      ).createShader(Rect.fromCircle(center: const Offset(40, 40), radius: 80));
    canvas.drawCircle(const Offset(40, 40), 80, sunGlow);

    // 2. Parallax Distant Hills in Background
    final hillPaint = Paint()..color = const Color(0xFF0284C7).withValues(alpha: 0.30);
    final hillPath = Path()
      ..moveTo(0, size.height - 40)
      ..quadraticBezierTo(size.width * 0.25, size.height - 70, size.width * 0.5, size.height - 45)
      ..quadraticBezierTo(size.width * 0.75, size.height - 25, size.width, size.height - 50)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hillPath, hillPaint);

    // 3. Background Floating Fluffy Clouds
    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    for (var c in bgClouds) {
      canvas.drawCircle(Offset(c.x, c.y), c.size, cloudPaint);
      canvas.drawCircle(Offset(c.x + c.size * 0.6, c.y - c.size * 0.3), c.size * 0.7, cloudPaint);
      canvas.drawCircle(Offset(c.x + c.size * 1.2, c.y), c.size * 0.8, cloudPaint);
    }

    // 4. Cloud Gates (Top Cloud Gate Y: 130, Bottom Cloud Gate Y: 330)
    _drawCloudGate(canvas, gateX, 130, currentWave.topText, currentWave.topCorrect);
    _drawCloudGate(canvas, gateX, 330, currentWave.bottomText, currentWave.bottomCorrect);

    // 5. Rolling Green Hills at bottom
    final groundPaint = Paint()..color = const Color(0xFF15803D);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 24, size.width, 24), groundPaint);
    final grassTopPaint = Paint()..color = const Color(0xFF4ADE80);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 24, size.width, 6), grassTopPaint);

    // 6. Particles (Rainbow Trail, Feathers & Bursts)
    for (var p in particles) {
      final pPaint = Paint()
        ..color = p.color.withValues(alpha: (p.life / p.maxLife).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x, p.y), p.radius, pPaint);
    }

    // 7. 🌟 70% Original Animated Cartoon Aviator Bird
    _drawBird(canvas, birdX, birdY, birdAngle);
  }

  void _drawCloudGate(Canvas canvas, double x, double y, String text, bool isCorrect) {
    canvas.save();
    canvas.translate(x, y);

    // Cloud shadow
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 5), width: 144, height: 78),
        const Radius.circular(24),
      ),
      shadowPaint,
    );

    // Glowing Neon Pulse Aura
    final double pulse = (sin(animTimer * 6) * 0.5 + 0.5);
    final auraPaint = Paint()
      ..color = (isCorrect ? const Color(0xFF10B981) : const Color(0xFF64748B))
          .withValues(alpha: 0.25 + pulse * 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 148, height: 82),
        const Radius.circular(26),
      ),
      auraPaint,
    );

    // Cloud Body with Soft 3D Gradient
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Color(0xFFF1F5F9)],
      ).createShader(Rect.fromCenter(center: Offset.zero, width: 140, height: 74));

    final borderPaint = Paint()
      ..color = isCorrect ? const Color(0xFF10B981) : const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 140, height: 74),
      const Radius.circular(22),
    );
    canvas.drawRRect(rrect, bodyPaint);
    canvas.drawRRect(rrect, borderPaint);

    // Top Cloud Puffs on Gate for extra fluffiness
    final puffPaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(-42, -30), 16, puffPaint);
    canvas.drawCircle(const Offset(0, -34), 18, puffPaint);
    canvas.drawCircle(const Offset(42, -30), 16, puffPaint);

    // Floating Golden Star Coin Indicator
    final starPaint = Paint()..color = isCorrect ? Colors.amber : const Color(0xFF94A3B8);
    canvas.drawCircle(const Offset(-52, 0), 6, starPaint);

    // Word Text Option (Crisp Bold Typography)
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 15.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(-tp.width / 2 + 5, -tp.height / 2));

    canvas.restore();
  }

  void _drawBird(Canvas canvas, double x, double y, double angle) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);

    final Paint paint = Paint()..isAntiAlias = true;

    // 1. Red Aviator Scarf Fluttering Behind Bird
    final scarfWave = sin(animTimer * 16) * 3;
    final Path scarf = Path()
      ..moveTo(-10, 3)
      ..quadraticBezierTo(-20, 2 + scarfWave, -28, 6 + scarfWave)
      ..lineTo(-26, 12 + scarfWave)
      ..quadraticBezierTo(-18, 8 + scarfWave, -8, 6)
      ..close();
    paint.color = const Color(0xFFEF4444);
    canvas.drawPath(scarf, paint);

    // 2. Cute Yellow Tail Feathers
    final Path tail = Path()
      ..moveTo(-12, -4)
      ..lineTo(-22, -8)
      ..lineTo(-18, -1)
      ..lineTo(-24, 2)
      ..lineTo(-12, 4)
      ..close();
    paint.color = const Color(0xFFEAB308);
    canvas.drawPath(tail, paint);

    // 3. Bird Body (Vibrant 3D Yellow Gradient Sphere)
    paint.shader = const RadialGradient(
      center: Alignment(-0.25, -0.35),
      colors: [Color(0xFFFEF08A), Color(0xFFFACC15), Color(0xFFEAB308)],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: 19));
    canvas.drawCircle(Offset.zero, 18.5, paint);
    paint.shader = null;

    // Soft feathered belly highlight
    paint.color = Colors.white.withValues(alpha: 0.35);
    canvas.drawCircle(const Offset(2, 6), 9, paint);

    // 4. Large Expressive Cartoon Eye
    paint.color = Colors.white;
    canvas.drawCircle(const Offset(8, -5), 6.0, paint);
    paint.color = const Color(0xFF0F172A);
    canvas.drawCircle(const Offset(10, -5), 3.2, paint);
    // Eye specular shine sparkles
    paint.color = Colors.white;
    canvas.drawCircle(const Offset(11.2, -6.5), 1.4, paint);
    canvas.drawCircle(const Offset(8.8, -3.8), 0.7, paint);

    // 5. Orange Beak with Smile Line
    final Path beak = Path()
      ..moveTo(14, -4)
      ..lineTo(26, 1)
      ..lineTo(14, 6)
      ..close();
    paint.color = const Color(0xFFF97316);
    canvas.drawPath(beak, paint);
    // Lower lip highlight
    paint.color = const Color(0xFFEA580C);
    canvas.drawLine(const Offset(14, 1), const Offset(22, 1), paint..strokeWidth = 1.0);

    // 6. Fluttering Animated Wing (Rotates with dynamic wing angle)
    canvas.save();
    canvas.translate(-4, 2);
    canvas.rotate(wingAngle);

    final Path wing = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-10, -14, -18, -6)
      ..quadraticBezierTo(-14, 6, 0, 4)
      ..close();
    paint.color = const Color(0xFFF59E0B);
    canvas.drawPath(wing, paint);

    // Inner wing feather layer
    final Path innerWing = Path()
      ..moveTo(-1, 0)
      ..quadraticBezierTo(-7, -9, -12, -4)
      ..quadraticBezierTo(-9, 4, -1, 3)
      ..close();
    paint.color = const Color(0xFFFBBF24);
    canvas.drawPath(innerWing, paint);

    canvas.restore();

    // 7. Golden Pilot Crest on top
    final Path crest = Path()
      ..moveTo(-2, -16)
      ..quadraticBezierTo(-5, -23, 1, -25)
      ..quadraticBezierTo(4, -20, 3, -16)
      ..close();
    paint.color = const Color(0xFFEAB308);
    canvas.drawPath(crest, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FlappyPainter oldDelegate) => true;
}
