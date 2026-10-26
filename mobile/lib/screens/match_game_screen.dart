import 'package:flutter/material.dart';

class MatchGameScreen extends StatefulWidget {
  final String title;

  const MatchGameScreen({
    super.key,
    this.title = 'Match It: Connect the Pairs',
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

class _MatchGameScreenState extends State<MatchGameScreen> {
  int _score = 0;
  int _lives = 3;
  int? _selectedLeftId;
  int? _selectedRightId;
  int? _errorLeftId;
  int? _errorRightId;
  String _gameState = 'playing'; // 'playing', 'victory', 'gameover'

  final List<_MatchPair> _pairs = [
    _MatchPair(id: 1, leftText: 'Enormous', rightText: 'Extremely Large', color: const Color(0xFF10B981)),
    _MatchPair(id: 2, leftText: 'Ancient', rightText: 'Belonging to Past', color: const Color(0xFF3B82F6)),
    _MatchPair(id: 3, leftText: 'Brilliant', rightText: 'Exceptionally Clever', color: const Color(0xFFF59E0B)),
    _MatchPair(id: 4, leftText: 'Silent', rightText: 'Completely Quiet', color: const Color(0xFF8B5CF6)),
    _MatchPair(id: 5, leftText: 'Swift', rightText: 'Moving Very Fast', color: const Color(0xFFEC4899)),
  ];

  late List<_MatchPair> _leftItems;
  late List<_MatchPair> _rightItems;
  final Set<int> _matchedIds = {};

  @override
  void initState() {
    super.initState();
    _startMatchGame();
  }

  void _startMatchGame() {
    _score = 0;
    _lives = 3;
    _matchedIds.clear();
    _selectedLeftId = null;
    _selectedRightId = null;
    _errorLeftId = null;
    _errorRightId = null;
    _gameState = 'playing';

    _leftItems = List.from(_pairs)..shuffle();
    _rightItems = List.from(_pairs)..shuffle();
  }

  void _onLeftTap(int id) {
    if (_matchedIds.contains(id) || _gameState != 'playing') return;

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
    if (_matchedIds.contains(id) || _gameState != 'playing') return;

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
    if (leftId == rightId) {
      // SUCCESSFUL MATCH!
      _matchedIds.add(leftId);
      _score += 100;
      _selectedLeftId = null;
      _selectedRightId = null;

      if (_matchedIds.length == _pairs.length) {
        _gameState = 'victory';
      }
    } else {
      // MISMATCH!
      _errorLeftId = leftId;
      _errorRightId = rightId;
      _lives--;

      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          _selectedLeftId = null;
          _selectedRightId = null;
          _errorLeftId = null;
          _errorRightId = null;
          if (_lives <= 0) _gameState = 'gameover';
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
            'MATCHED: ${_matchedIds.length}/${_pairs.length}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 0.8,
            ),
          ),
          Row(
            children: List.generate(
              3,
              (i) => Icon(
                i < _lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: i < _lives ? const Color(0xFFEF4444) : Colors.white24,
                size: 18,
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
      color: const Color(0xFF0D1B2A),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.extension_rounded, color: Color(0xFF10B981), size: 14),
              SizedBox(width: 6),
              Text(
                'MATCH MISSION',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 2),
          Text(
            'Tap a word on the left, then tap its matching meaning on the right!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12),
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
