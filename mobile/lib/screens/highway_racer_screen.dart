import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HighwayRacerScreen extends StatefulWidget {
  final String title;

  const HighwayRacerScreen({
    super.key,
    this.title = 'Highway Racer: Irregular Past Tense',
  });

  @override
  State<HighwayRacerScreen> createState() => _HighwayRacerScreenState();
}

class _HighwayRacerScreenState extends State<HighwayRacerScreen> with TickerProviderStateMixin {
  // Game Loop & State
  int _score = 0;
  int _lives = 3;
  int _streak = 0;
  int _currentChallenge = 0;
  bool _soundEnabled = true;
  String _gameState = 'playing'; // 'playing', 'victory', 'gameover'
  bool _nitroActive = false;

  // Road & Car Animation
  double _roadOffset = 0;
  int _playerLane = 1; // 0: Left, 1: Middle, 2: Right
  double _playerCarX = 1.0; // Animated lane position: 0.0, 1.0, 2.0
  double _waveY = -100; // Vertical position of oncoming cars (pixels from top)
  bool _waveActive = true;
  Timer? _gameLoopTimer;

  // Feedback effects
  String? _feedbackText;
  Color? _feedbackColor;
  bool _screenFlash = false;
  Color _flashColor = Colors.transparent;

  // Database Challenges (Matching web Irregular Past Tense questions)
  final List<Map<String, dynamic>> _challenges = [
    {
      'question': 'Steer to the Past Tense of "Drive":',
      'options': [
        {'text': 'Drove', 'isCorrect': true},
        {'text': 'Drived', 'isCorrect': false},
        {'text': 'Drives', 'isCorrect': false},
      ],
    },
    {
      'question': 'Steer to the Past Tense of "Write":',
      'options': [
        {'text': 'Writing', 'isCorrect': false},
        {'text': 'Wrote', 'isCorrect': true},
        {'text': 'Written', 'isCorrect': false},
      ],
    },
    {
      'question': 'Steer to the Past Tense of "Go":',
      'options': [
        {'text': 'Goes', 'isCorrect': false},
        {'text': 'Going', 'isCorrect': false},
        {'text': 'Went', 'isCorrect': true},
      ],
    },
    {
      'question': 'Steer to the Past Tense of "Eat":',
      'options': [
        {'text': 'Eating', 'isCorrect': false},
        {'text': 'Ate', 'isCorrect': true},
        {'text': 'Eaten', 'isCorrect': false},
      ],
    },
    {
      'question': 'Steer to the Past Tense of "Buy":',
      'options': [
        {'text': 'Bought', 'isCorrect': true},
        {'text': 'Buyed', 'isCorrect': false},
        {'text': 'Buying', 'isCorrect': false},
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAnimationLoop();
  }

  @override
  void dispose() {
    _gameLoopTimer?.cancel();
    super.dispose();
  }

  void _startAnimationLoop() {
    _gameLoopTimer?.cancel();
    _waveY = -100;
    _waveActive = true;

    // 60 FPS tick (every 16ms)
    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_gameState != 'playing') return;

      setState(() {
        final roadSpeed = _nitroActive ? 12.0 : 5.0;
        _roadOffset += roadSpeed;

        // Smoothly lerp car X position towards target lane
        _playerCarX += (_playerLane.toDouble() - _playerCarX) * 0.35;

        if (_waveActive) {
          final waveSpeed = _nitroActive ? 5.5 : 2.5;
          _waveY += waveSpeed;

          // Check collision when oncoming wave reaches player car area (near bottom)
          if (_waveY >= 360) {
            _checkCollision();
          }
        }
      });
    });
  }

  void _steerLeft() {
    if (_gameState != 'playing') return;
    if (_playerLane > 0) {
      setState(() {
        _playerLane--;
        _playerCarX = _playerLane.toDouble();
      });
    }
  }

  void _steerRight() {
    if (_gameState != 'playing') return;
    if (_playerLane < 2) {
      setState(() {
        _playerLane++;
        _playerCarX = _playerLane.toDouble();
      });
    }
  }

  void _setLane(int lane) {
    if (_gameState != 'playing') return;
    if (lane >= 0 && lane <= 2) {
      setState(() {
        _playerLane = lane;
        _playerCarX = lane.toDouble();
      });
    }
  }

  void _activateNitro() {
    if (_gameState != 'playing' || _nitroActive) return;
    setState(() => _nitroActive = true);
    Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _nitroActive = false);
    });
  }

  void _checkCollision() {
    _waveActive = false;
    final current = _challenges[_currentChallenge];
    final options = current['options'] as List;
    final chosenOption = options[_playerLane];

    if (chosenOption['isCorrect'] == true) {
      // SUCCESS HIT!
      final bonus = _nitroActive ? 150 : 100;
      _score += bonus;
      _streak++;
      _feedbackText = 'PERFECT! +$bonus 🎯';
      _feedbackColor = const Color(0xFF10B981);
      _flashScreen(const Color(0xFF10B981).withValues(alpha: 0.3));

      Timer(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        if (_currentChallenge < _challenges.length - 1) {
          setState(() {
            _currentChallenge++;
            _waveY = -80;
            _waveActive = true;
            _feedbackText = null;
          });
        } else {
          setState(() => _gameState = 'victory');
        }
      });
    } else {
      // CRASH!
      _streak = 0;
      _lives--;
      _feedbackText = 'CRASH! 💥';
      _feedbackColor = const Color(0xFFEF4444);
      _flashScreen(const Color(0xFFEF4444).withValues(alpha: 0.4));

      if (_lives <= 0) {
        Timer(const Duration(milliseconds: 700), () {
          if (mounted) setState(() => _gameState = 'gameover');
        });
      } else {
        Timer(const Duration(milliseconds: 1200), () {
          if (!mounted) return;
          setState(() {
            _waveY = -80;
            _waveActive = true;
            _feedbackText = null;
          });
        });
      }
    }
  }

  void _flashScreen(Color color) {
    setState(() {
      _screenFlash = true;
      _flashColor = color;
    });
    Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _screenFlash = false);
    });
  }

  void _restartGame() {
    setState(() {
      _score = 0;
      _lives = 3;
      _streak = 0;
      _currentChallenge = 0;
      _gameState = 'playing';
      _playerLane = 1;
      _playerCarX = 1.0;
      _waveY = -80;
      _waveActive = true;
      _feedbackText = null;
      _nitroActive = false;
    });
    _startAnimationLoop();
  }

  @override
  Widget build(BuildContext context) {
    final current = _challenges[_currentChallenge];

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.keyA) {
            _steerLeft();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight || event.logicalKey == LogicalKeyboardKey.keyD) {
            _steerRight();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp || event.logicalKey == LogicalKeyboardKey.space) {
            _activateNitro();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
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
                        // 1. TOP HUD BAR (Matching user's photo)
                        _buildTopHud(),

                        // 2. TARGET OBJECTIVE BANNER (Matching user's photo)
                        _buildObjectiveBanner(current['question']),

                        // 3. ROAD CANVAS WITH CURBS, DIVIDERS & CARS
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapDown: (details) {
                                  final tapX = details.localPosition.dx;
                                  final laneWidth = constraints.maxWidth / 3;
                                  final lane = (tapX / laneWidth).floor().clamp(0, 2);
                                  _setLane(lane);
                                },
                                onHorizontalDragUpdate: (details) {
                                  if (details.delta.dx < -8) {
                                    _steerLeft();
                                  } else if (details.delta.dx > 8) {
                                    _steerRight();
                                  }
                                },
                                child: Stack(
                                  children: [
                                    // Asphalt Road with Red/White Curbs & Dashed Dividers
                                    CustomPaint(
                                      painter: _RoadPainter(
                                        roadOffset: _roadOffset,
                                        nitroActive: _nitroActive,
                                      ),
                                      child: Container(),
                                    ),

                                    // Oncoming Waves (3 Lanes Cars with Word Plates)
                                    if (_waveActive && _gameState == 'playing')
                                      _buildOncomingCars(current['options']),

                                    // Player Car (Red Sports Racer at bottom)
                                    _buildPlayerCar(),

                                    // Floating Feedback (+100 PERFECT or CRASH)
                                    if (_feedbackText != null)
                                      Positioned(
                                        top: 280,
                                        left: 0,
                                        right: 0,
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: _feedbackColor?.withValues(alpha: 0.95),
                                              borderRadius: BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.5),
                                                  blurRadius: 10,
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              _feedbackText!,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                    // Screen Flash Effect
                                    if (_screenFlash)
                                      Positioned.fill(
                                        child: Container(color: _flashColor),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        // 4. TOUCH CONTROLS BAR (LEFT, NITRO, RIGHT) (Matching user's photo)
                        _buildControlsBar(),
                      ],
                    ),

                    // Overlay: Victory / Game Over
                    if (_gameState == 'victory') _buildVictoryOverlay(),
                    if (_gameState == 'gameover') _buildGameOverOverlay(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- TOP HUD BAR ---
  Widget _buildTopHud() {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Score & Trophy
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 20),
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
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Text(
                    '🔥 ${_streak}x',
                    style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),

          // Challenge Tracker
          Text(
            'CHALLENGE ${_currentChallenge + 1}/${_challenges.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),

          // Lives (Hearts) & Sound
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

  // --- TARGET OBJECTIVE BANNER ---
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
              Icon(Icons.track_changes_rounded, color: Color(0xFFF59E0B), size: 14),
              SizedBox(width: 6),
              Text(
                'TARGET OBJECTIVE',
                style: TextStyle(
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
            question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --- ONCOMING CARS (3 LANES) ---
  Widget _buildOncomingCars(List options) {
    return Positioned(
      top: _waveY,
      left: 0,
      right: 0,
      child: Row(
        children: List.generate(3, (laneIdx) {
          final opt = options[laneIdx];
          final bool isCorrect = opt['isCorrect'] == true;

          return Expanded(
            child: Column(
              children: [
                // Word Tag Plate
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isCorrect ? const Color(0xFF0284C7) : const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCorrect ? const Color(0xFF38BDF8) : Colors.white24,
                      width: 1.5,
                    ),
                    boxShadow: [
                      if (isCorrect)
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.6),
                          blurRadius: 10,
                        ),
                    ],
                  ),
                  child: Text(
                    opt['text'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Oncoming Car (Blue sports car for correct, Police/Obstacle car for wrong)
                Container(
                  width: 38,
                  height: 68,
                  decoration: BoxDecoration(
                    color: isCorrect ? const Color(0xFF0284C7) : const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCorrect ? Colors.cyanAccent : Colors.white70,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isCorrect ? Colors.cyanAccent : Colors.black).withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Roof light
                      Container(
                        width: 12,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isCorrect ? Colors.amber : Colors.redAccent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Windshield
                      Container(
                        width: 26,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Headlights
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(width: 5, height: 5, color: Colors.yellowAccent),
                          Container(width: 5, height: 5, color: Colors.yellowAccent),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // --- PLAYER RACER CAR (Visible and animated at bottom) ---
  Widget _buildPlayerCar() {
    return Positioned(
      bottom: 12,
      left: 0,
      right: 0,
      height: 95,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final laneWidth = constraints.maxWidth / 3;
          final carLeft = (_playerCarX * laneWidth) + (laneWidth / 2) - 22;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: carLeft,
                top: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Red Racing Sports Car (Matching photo & web canvas player car)
                    Container(
                      width: 44,
                      height: 74,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626), // Vibrant Racing Red
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber, width: 2.2),
                        boxShadow: [
                          BoxShadow(
                            color: (_nitroActive ? Colors.cyanAccent : Colors.redAccent).withValues(alpha: 0.85),
                            blurRadius: _nitroActive ? 24 : 14,
                            spreadRadius: _nitroActive ? 4 : 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Yellow Center Racing Stripes
                          Center(
                            child: Container(
                              width: 8,
                              height: 74,
                              color: Colors.amber,
                            ),
                          ),
                          // Front Headlights
                          Positioned(
                            top: 3,
                            left: 4,
                            right: 4,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 6,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.yellowAccent,
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.yellowAccent, blurRadius: 4),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 6,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.yellowAccent,
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.yellowAccent, blurRadius: 4),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Windshield
                          Positioned(
                            top: 14,
                            left: 6,
                            right: 6,
                            child: Container(
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.white24, width: 1),
                              ),
                            ),
                          ),
                          // Rear Window
                          Positioned(
                            top: 42,
                            left: 8,
                            right: 8,
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          // Rear spoiler
                          Positioned(
                            bottom: 2,
                            left: 2,
                            right: 2,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Exhaust Nitro Smoke / Flames
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: _nitroActive ? 16 : 8,
                          decoration: BoxDecoration(
                            color: _nitroActive ? Colors.cyanAccent : Colors.orangeAccent,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: _nitroActive ? Colors.cyanAccent : Colors.orangeAccent,
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          width: 7,
                          height: _nitroActive ? 16 : 8,
                          decoration: BoxDecoration(
                            color: _nitroActive ? Colors.cyanAccent : Colors.orangeAccent,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: _nitroActive ? Colors.cyanAccent : Colors.orangeAccent,
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- TOUCH CONTROLS BAR (Instant Response Touch & Click) ---
  Widget _buildControlsBar() {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // LEFT BUTTON
          Expanded(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => _steerLeft(),
              child: GestureDetector(
                onTap: _steerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white38, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_circle_left_rounded, color: Colors.cyanAccent, size: 24),
                      SizedBox(width: 6),
                      Text(
                        'LEFT',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // NITRO BUTTON
          Expanded(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => _activateNitro(),
              child: GestureDetector(
                onTap: _activateNitro,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bolt_rounded, color: Colors.black, size: 22),
                      SizedBox(width: 4),
                      Text(
                        'NITRO',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // RIGHT BUTTON
          Expanded(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => _steerRight(),
              child: GestureDetector(
                onTap: _steerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white38, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'RIGHT',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_circle_right_rounded, color: Colors.cyanAccent, size: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- VICTORY OVERLAY ---
  Widget _buildVictoryOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏁 TRACK CLEARED! 🏆', style: TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Outstanding Driving & Grammar Mastery!', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 16),
              Text('Final Score: $_score Speed XP', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _restartGame,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
                child: const Text('Race Again 🔄', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Games', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- GAMEOVER OVERLAY ---
  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.redAccent, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💥 CRASHED OUT! 🚧', style: TextStyle(color: Colors.redAccent, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Vehicle shields depleted. Review past tense verbs!', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 16),
              Text('Score: $_score XP', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _restartGame,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                child: const Text('Retry Track 🔄', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Games', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Painter for Asphalt Road, Red-and-White Curbs & Dashed Lane Dividers
class _RoadPainter extends CustomPainter {
  final double roadOffset;
  final bool nitroActive;

  _RoadPainter({required this.roadOffset, required this.nitroActive});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Asphalt Road Background
    final asphaltPaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), asphaltPaint);

    // 2. Red and White Alternating Curbs (Left & Right borders)
    const curbWidth = 10.0;
    const stripeHeight = 24.0;
    final redPaint = Paint()..color = const Color(0xFFDC2626);
    final whitePaint = Paint()..color = Colors.white;

    for (double y = (roadOffset % (stripeHeight * 2)) - (stripeHeight * 2); y < size.height; y += stripeHeight) {
      final isRed = ((y - roadOffset) / stripeHeight).floor() % 2 == 0;
      final paint = isRed ? redPaint : whitePaint;

      // Left curb
      canvas.drawRect(Rect.fromLTWH(0, y, curbWidth, stripeHeight), paint);
      // Right curb
      canvas.drawRect(Rect.fromLTWH(size.width - curbWidth, y, curbWidth, stripeHeight), paint);
    }

    // 3. Lane Dividers (2 White Dashed Lines separating 3 lanes)
    final laneWidth = size.width / 3;
    final dividerPaint = Paint()
      ..color = Colors.white.withValues(alpha: nitroActive ? 0.9 : 0.7)
      ..strokeWidth = 3.5;

    const dashHeight = 26.0;
    const dashGap = 20.0;

    for (int lane = 1; lane <= 2; lane++) {
      final x = lane * laneWidth;
      for (double y = (roadOffset % (dashHeight + dashGap)) - (dashHeight + dashGap); y < size.height; y += (dashHeight + dashGap)) {
        canvas.drawLine(Offset(x, y), Offset(x, y + dashHeight), dividerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) {
    return oldDelegate.roadOffset != roadOffset || oldDelegate.nitroActive != nitroActive;
  }
}
