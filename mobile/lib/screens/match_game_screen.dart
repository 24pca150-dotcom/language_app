import 'dart:math';
import 'package:flutter/material.dart';
import '../services/game_service.dart';
import '../data/game_question_bank.dart';

class MatchGameScreen extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? dataJson;

  const MatchGameScreen({
    super.key,
    this.title = 'Match It: Connect the Pairs',
    this.dataJson,
  });

  @override
  State<MatchGameScreen> createState() => _MatchGameScreenState();
}

class _MatchPair {
  final int id;
  final String leftText;
  final String rightText;
  final Color color;

  _MatchPair({
    required this.id,
    required this.leftText,
    required this.rightText,
    required this.color,
  });
}

class _MatchGameScreenState extends State<MatchGameScreen> with SingleTickerProviderStateMixin {
  int _score = 0;
  int _lives = 5;
  int? _selectedLeftId;
  int? _selectedRightId;
  int? _errorLeftId;
  int? _errorRightId;
  String _gameState = 'playing'; // 'playing', 'victory', 'gameover'

  final List<_MatchPair> _pairs = [];

  late List<_MatchPair> _leftItems;
  late List<_MatchPair> _rightItems;
  final Set<int> _matchedIds = {};

  // 🚂 70% Original Train Journey Animation
  late AnimationController _trainController;
  bool _isTrainRunning = false;
  bool _isTrainSuccess = false;
  int _trainFromIndex = 0;
  int _trainToIndex = 0;
  int? _activeLeftId;
  String? _trainFeedback;

  @override
  void initState() {
    super.initState();
    _trainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _trainController.addListener(() {
      setState(() {});
    });
    _trainController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isTrainSuccess) {
        setState(() {
          if (_activeLeftId != null) {
            _matchedIds.add(_activeLeftId!);
          }
          _score += 100;
          _trainFeedback = 'CHOO CHOO! 🚂 ROUTE CONNECTED! +100';
          _selectedLeftId = null;
          _selectedRightId = null;
          _isTrainRunning = false;
          if (_matchedIds.length == _pairs.length) {
            _gameState = 'victory';
          }
        });
      }
    });
    _startMatchGame();
  }

  @override
  void dispose() {
    _recordResult();
    _trainController.dispose();
    super.dispose();
  }

  void _recordResult() {
    if (_score <= 0) return;
    GameService.recordActivity('match', count: _score ~/ 100);
  }

  void _startMatchGame() {
    _recordResult();
    _score = 0;
    _lives = 5;
    _matchedIds.clear();
    _selectedLeftId = null;
    _selectedRightId = null;
    _errorLeftId = null;
    _errorRightId = null;
    _isTrainRunning = false;
    _trainFeedback = null;
    _gameState = 'playing';
    _pairs.clear();

    final colors = [
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF0D9488),
      const Color(0xFFE11D48),
    ];

    final dj = widget.dataJson;
    final List<_MatchPair> dynamicPairs = [];
    if (dj != null && dj['pairs'] is List && (dj['pairs'] as List).isNotEmpty) {
      int pId = 1;
      for (var p in dj['pairs']) {
        if (p is! Map<String, dynamic>) continue;
        final left = (p['left'] ?? p['word'] ?? '').toString();
        final right = (p['right'] ?? p['match'] ?? p['meaning'] ?? '').toString();
        if (left.isNotEmpty && right.isNotEmpty) {
          dynamicPairs.add(_MatchPair(
            id: pId,
            leftText: left,
            rightText: right,
            color: colors[(pId - 1) % colors.length],
          ));
          pId++;
        }
      }
    }

    if (dynamicPairs.isNotEmpty) {
      dynamicPairs.shuffle();
      _pairs.addAll(dynamicPairs.take(5));
    } else {
      final randomPool = GameQuestionBank.getRandomMatchPairs(5);
      for (int i = 0; i < randomPool.length; i++) {
        final pair = randomPool[i];
        _pairs.add(_MatchPair(
          id: i + 1,
          leftText: pair['left'] as String,
          rightText: pair['right'] as String,
          color: colors[i % colors.length],
        ));
      }
    }

    _leftItems = List.from(_pairs)..shuffle();
    _rightItems = List.from(_pairs)..shuffle();
  }

  void _onLeftTap(int id) {
    if (_matchedIds.contains(id) || _gameState != 'playing' || _isTrainRunning) return;

    setState(() {
      _selectedLeftId = id;
      _errorLeftId = null;
      _errorRightId = null;

      if (_selectedRightId != null) {
        _checkMatch(id, _selectedRightId!);
      }
    });
  }

  void _onRightTap(int id) {
    if (_matchedIds.contains(id) || _gameState != 'playing' || _isTrainRunning) return;

    setState(() {
      _selectedRightId = id;
      _errorLeftId = null;
      _errorRightId = null;

      if (_selectedLeftId != null) {
        _checkMatch(_selectedLeftId!, id);
      }
    });
  }

  void _checkMatch(int leftId, int rightId) {
    if (_isTrainRunning) return;

    final fromIdx = _leftItems.indexWhere((e) => e.id == leftId);
    final toIdx = _rightItems.indexWhere((e) => e.id == rightId);
    final bool isSuccess = (leftId == rightId);

    setState(() {
      _activeLeftId = leftId;
      _isTrainRunning = true;
      _isTrainSuccess = isSuccess;
      _trainFromIndex = fromIdx >= 0 ? fromIdx : 0;
      _trainToIndex = toIdx >= 0 ? toIdx : 0;
      _trainFeedback = isSuccess ? 'Train Departing to Destination... 🚂💨' : 'Checking Route... 🚂';
    });

    if (isSuccess) {
      _trainController.forward(from: 0.0);
    } else {
      // 🛑 EMERGENCY BRAKE ANIMATION: Train halts midway, sparks fly!
      _trainController
          .animateTo(0.48, duration: const Duration(milliseconds: 400), curve: Curves.easeOut)
          .then((_) {
        if (!mounted) return;
        setState(() {
          _errorLeftId = leftId;
          _errorRightId = rightId;
          _trainFeedback = '🛑 EMERGENCY BRAKE! WRONG ANSWER!';
          _lives--;
        });

        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          setState(() {
            _selectedLeftId = null;
            _selectedRightId = null;
            _errorLeftId = null;
            _errorRightId = null;
            _isTrainRunning = false;
            _trainFeedback = null;
            _trainController.reset();
            if (_lives <= 0) _gameState = 'gameover';
          });
        });
      });
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
                  // 1. 🏞️ Real Scenic Landscape Background (Railway Track setting)
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/kids_landscape_bg.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF1E293B)),
                    ),
                  ),

                  // 2. Dark Landscape Vignette Gradient Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.72),
                            Colors.black.withValues(alpha: 0.45),
                            Colors.black.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Game Content Layout
                  Column(
                    children: [
                      // Top HUD
                      _buildTopHud(),

                      // Mission Banner
                      _buildObjectiveBanner(),

                      // 2 Matching Columns
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Left Column (Words)
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: _leftItems.map((item) {
                                    final isMatched = _matchedIds.contains(item.id);
                                    final isSelected = _selectedLeftId == item.id;
                                    final isError = _errorLeftId == item.id;
                                    return _buildCard(
                                      text: item.leftText,
                                      isMatched: isMatched,
                                      isSelected: isSelected,
                                      isError: isError,
                                      color: item.color,
                                      onTap: () => _onLeftTap(item.id),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Right Column (Meanings)
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: _rightItems.map((item) {
                                    final isMatched = _matchedIds.contains(item.id);
                                    final isSelected = _selectedRightId == item.id;
                                    final isError = _errorRightId == item.id;
                                    return _buildCard(
                                      text: item.rightText,
                                      isMatched: isMatched,
                                      isSelected: isSelected,
                                      isError: isError,
                                      color: item.color,
                                      onTap: () => _onRightTap(item.id),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 4. 🚂 Train Tracks & Moving Steam Locomotive Canvas Overlay
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _TrainRailwayPainter(
                          progress: _trainController.value,
                          fromIndex: _trainFromIndex,
                          toIndex: _trainToIndex,
                          isRunning: _isTrainRunning,
                          isSuccess: _isTrainSuccess,
                          matchedIds: _matchedIds,
                          leftItems: _leftItems,
                          rightItems: _rightItems,
                        ),
                      ),
                    ),
                  ),

                  // 5. Train Status / Feedback Floating Banner
                  if (_trainFeedback != null)
                    Positioned(
                      top: 100,
                      left: 20,
                      right: 20,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isTrainSuccess
                                ? const Color(0xFF10B981).withValues(alpha: 0.95)
                                : const Color(0xFFEF4444).withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3))],
                          ),
                          child: Text(
                            _trainFeedback!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
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
                'MATCHED: ${_matchedIds.length}/${_pairs.length}',
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
            children: List.generate(
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
          ),
        ],
      ),
    );
  }

  Widget _buildObjectiveBanner() {
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
          color: const Color(0xFF10B981).withValues(alpha: 0.8),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.35),
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
              color: const Color(0xFF059669).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.train_rounded, color: Color(0xFF10B981), size: 13),
                SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'RAILWAY MATCH MISSION',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF10B981),
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
          const Text(
            'Tap a word on the left, then connect it to its meaning on the right!',
            textAlign: TextAlign.center,
            style: TextStyle(
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

  Widget _buildCard({
    required String text,
    required bool isMatched,
    required bool isSelected,
    required bool isError,
    required Color color,
    required VoidCallback onTap,
  }) {
    Color borderColor = Colors.white24;
    Color bgColor = const Color(0xFF0F172A);
    Color textColor = Colors.white;

    if (isMatched) {
      borderColor = color;
      bgColor = color.withValues(alpha: 0.2);
      textColor = color;
    } else if (isError) {
      borderColor = const Color(0xFFEF4444);
      bgColor = const Color(0xFFEF4444).withValues(alpha: 0.3);
      textColor = const Color(0xFFFCA5A5);
    } else if (isSelected) {
      borderColor = const Color(0xFF38BDF8);
      bgColor = const Color(0xFF38BDF8).withValues(alpha: 0.25);
      textColor = const Color(0xFF38BDF8);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isSelected || isMatched ? 2.0 : 1.2),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isMatched ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isMatched ? textColor : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (isMatched) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.check_circle_rounded, color: color, size: 16),
                ],
              ],
            ),
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
              const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 64),
              const SizedBox(height: 12),
              const Text(
                '🎉 ALL PAIRS MATCHED!',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Outstanding vocabulary and pairing precision!',
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
                  'Score: $_score XP',
                  style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => setState(_startMatchGame),
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
              const Icon(Icons.heart_broken_rounded, color: Color(0xFFEF4444), size: 64),
              const SizedBox(height: 12),
              const Text(
                'OUT OF ATTEMPTS!',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Take your time to read the words and definitions carefully.',
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
                  'Score: $_score XP',
                  style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => setState(_startMatchGame),
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

// ==============================================================================
// 🚂 70% Original Train Railway Canvas Painter: Moving Steam Locomotive on Tracks
// ==============================================================================
class _TrainRailwayPainter extends CustomPainter {
  final double progress;
  final int fromIndex;
  final int toIndex;
  final bool isRunning;
  final bool isSuccess;
  final Set<int> matchedIds;
  final List<_MatchPair> leftItems;
  final List<_MatchPair> rightItems;

  _TrainRailwayPainter({
    required this.progress,
    required this.fromIndex,
    required this.toIndex,
    required this.isRunning,
    required this.isSuccess,
    required this.matchedIds,
    required this.leftItems,
    required this.rightItems,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double topOffset = 135.0;
    final double availableHeight = size.height - topOffset - 25.0;
    final double rowHeight = availableHeight / 5.0;

    final double leftX = size.width * 0.44;
    final double rightX = size.width * 0.56;

    // 1. Draw permanently connected glowing tracks for already matched pairs
    for (var id in matchedIds) {
      final leftIdx = leftItems.indexWhere((e) => e.id == id);
      final rightIdx = rightItems.indexWhere((e) => e.id == id);
      if (leftIdx >= 0 && rightIdx >= 0) {
        final startY = topOffset + rowHeight * (leftIdx + 0.5);
        final endY = topOffset + rowHeight * (rightIdx + 0.5);

        final trackPaint = Paint()
          ..color = const Color(0xFF10B981).withValues(alpha: 0.85)
          ..strokeWidth = 3.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

        canvas.drawLine(Offset(leftX - 8, startY), Offset(rightX + 8, endY), trackPaint);

        final corePaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 1.4;
        canvas.drawLine(Offset(leftX - 8, startY), Offset(rightX + 8, endY), corePaint);
      }
    }

    // 2. Active Railway Route & Steam Train Journey
    if (isRunning) {
      final double startY = topOffset + rowHeight * (fromIndex + 0.5);
      final double endY = topOffset + rowHeight * (toIndex + 0.5);
      final startPos = Offset(size.width * 0.36, startY);
      final endPos = Offset(size.width * 0.64, endY);

      final double dx = endPos.dx - startPos.dx;
      final double dy = endPos.dy - startPos.dy;
      final double angle = atan2(dy, dx);
      final double distance = sqrt(dx * dx + dy * dy);

      // A. Railway Track (Timber Ties & Dual Metal Rails)
      final trackPaint = Paint()
        ..color = const Color(0xFF78350F)
        ..strokeWidth = 2.0;

      const double tieSpacing = 14.0;
      final int tieCount = (distance / tieSpacing).floor();
      final double normalX = -sin(angle);
      final double normalY = cos(angle);

      for (int i = 0; i <= tieCount; i++) {
        final double t = (i * tieSpacing) / distance;
        final double tieCenterX = startPos.dx + dx * t;
        final double tieCenterY = startPos.dy + dy * t;
        const double tieHalfLen = 9.0;
        canvas.drawLine(
          Offset(tieCenterX - normalX * tieHalfLen, tieCenterY - normalY * tieHalfLen),
          Offset(tieCenterX + normalX * tieHalfLen, tieCenterY + normalY * tieHalfLen),
          trackPaint,
        );
      }

      // Draw two steel rails
      final railPaint = Paint()
        ..color = (isSuccess ? const Color(0xFF38BDF8) : const Color(0xFFEF4444)).withValues(alpha: 0.9)
        ..strokeWidth = 1.8;

      const double railDist = 4.5;
      canvas.drawLine(
        Offset(startPos.dx - normalX * railDist, startPos.dy - normalY * railDist),
        Offset(endPos.dx - normalX * railDist, endPos.dy - normalY * railDist),
        railPaint,
      );
      canvas.drawLine(
        Offset(startPos.dx + normalX * railDist, startPos.dy + normalY * railDist),
        Offset(endPos.dx + normalX * railDist, endPos.dy + normalY * railDist),
        railPaint,
      );

      // B. 🚂 Steam Train Locomotive Engine
      final double curX = startPos.dx + dx * progress;
      final double curY = startPos.dy + dy * progress;

      canvas.save();
      canvas.translate(curX, curY);
      canvas.rotate(angle);

      final Paint trainPaint = Paint()..isAntiAlias = true;

      // Chimney Steam Puffs (Expanding white smoke clouds)
      for (int p = 0; p < 3; p++) {
        final double steamP = (progress * 5 + p * 0.3) % 1.0;
        final double sx = -14.0 - steamP * 18.0;
        final double sy = -6.0 - steamP * 8.0;
        final Paint steamPaint = Paint()
          ..color = Colors.white.withValues(alpha: (0.75 - steamP * 0.6).clamp(0.0, 1.0));
        canvas.drawCircle(Offset(sx, sy), 3.0 + steamP * 5.0, steamPaint);
      }

      // Headlight Beam shining forward
      final headlightGlow = Paint()
        ..shader = LinearGradient(
          colors: [
            (isSuccess ? Colors.amberAccent : Colors.redAccent).withValues(alpha: 0.6),
            Colors.transparent,
          ],
        ).createShader(const Rect.fromLTWH(12, -8, 28, 16));
      final Path headlightCone = Path()
        ..moveTo(12, 0)
        ..lineTo(38, -8)
        ..lineTo(38, 8)
        ..close();
      canvas.drawPath(headlightCone, headlightGlow);

      // Train Engine Chassis & Boiler (Navy / Black Locomotive)
      trainPaint.shader = const LinearGradient(
        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTWH(-14, -6, 26, 12));
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-14, -6, 26, 12), const Radius.circular(3)),
        trainPaint,
      );
      trainPaint.shader = null;

      // Brass Boiler Bands
      trainPaint.color = Colors.amber;
      canvas.drawLine(const Offset(-4, -6), const Offset(-4, 6), trainPaint..strokeWidth = 1.2);
      canvas.drawLine(const Offset(3, -6), const Offset(3, 6), trainPaint..strokeWidth = 1.2);

      // Red Driver Cabin at back
      trainPaint.color = const Color(0xFFDC2626);
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-14, -8, 9, 16), const Radius.circular(2)),
        trainPaint,
      );
      // Cabin warm window
      trainPaint.color = Colors.yellowAccent;
      canvas.drawRect(const Rect.fromLTWH(-12, -5, 5, 5), trainPaint);

      // Smokestack / Chimney on front
      trainPaint.color = const Color(0xFFD97706);
      canvas.drawRect(const Rect.fromLTWH(6, -9, 4, 4), trainPaint);

      // Front Cowcatcher
      final Path cowcatcher = Path()
        ..moveTo(12, -5)
        ..lineTo(17, 0)
        ..lineTo(12, 5)
        ..close();
      trainPaint.color = const Color(0xFFF59E0B);
      canvas.drawPath(cowcatcher, trainPaint);

      // Wheels
      trainPaint.color = const Color(0xFF0F172A);
      canvas.drawCircle(const Offset(-8, 6), 3, trainPaint);
      canvas.drawCircle(const Offset(0, 6), 3, trainPaint);
      canvas.drawCircle(const Offset(8, 6), 3, trainPaint);

      // C. Sparks if Emergency Brake!
      if (!isSuccess && progress >= 0.44) {
        final sparkPaint = Paint()..color = Colors.amberAccent;
        for (int s = 0; s < 5; s++) {
          final double sparkAngle = s * 0.8;
          canvas.drawCircle(
            Offset(cos(sparkAngle) * 8 - 4, sin(sparkAngle) * 8 + 6),
            1.5,
            sparkPaint,
          );
        }
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _TrainRailwayPainter oldDelegate) => true;
}
