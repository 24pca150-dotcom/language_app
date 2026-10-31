import 'package:flutter/material.dart';
import '../services/game_audio_service.dart';

class CrosswordGameScreen extends StatefulWidget {
  final String title;

  const CrosswordGameScreen({
    super.key,
    this.title = 'Crossword Quest: Vocabulary Grid',
  });

  @override
  State<CrosswordGameScreen> createState() => _CrosswordGameScreenState();
}

class _CrosswordClue {
  final int number;
  final String direction; // 'across' or 'down'
  final String clue;
  final String answer;
  final int startRow;
  final int startCol;

  _CrosswordClue({
    required this.number,
    required this.direction,
    required this.clue,
    required this.answer,
    required this.startRow,
    required this.startCol,
  });
}

class _CrosswordGameScreenState extends State<CrosswordGameScreen> {
  static const int gridSize = 6;
  int _score = 0;
  int _lives = 5;
  int? _selectedRow;
  int? _selectedCol;
  _CrosswordClue? _activeClue;

  late final FocusNode _keyboardFocusNode;
  late final TextEditingController _textEditingController;

  late List<List<String>> _grid;
  late List<List<String>> _solution;
  late List<List<int?>> _cellNumbers;

  final List<_CrosswordClue> _clues = [
    _CrosswordClue(
      number: 1,
      direction: 'across',
      clue: 'Opposite of old; modern or recent',
      answer: 'NEW',
      startRow: 0,
      startCol: 0,
    ),
    _CrosswordClue(
      number: 2,
      direction: 'across',
      clue: 'Past tense of run',
      answer: 'RAN',
      startRow: 2,
      startCol: 1,
    ),
    _CrosswordClue(
      number: 3,
      direction: 'across',
      clue: 'A large four-legged animal that purrs',
      answer: 'CAT',
      startRow: 4,
      startCol: 2,
    ),
    _CrosswordClue(
      number: 1,
      direction: 'down',
      clue: 'A bird builds this home with twigs',
      answer: 'NEST',
      startRow: 0,
      startCol: 0,
    ),
    _CrosswordClue(
      number: 4,
      direction: 'down',
      clue: 'To consume food',
      answer: 'EAT',
      startRow: 0,
      startCol: 1,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _keyboardFocusNode = FocusNode();
    _textEditingController = TextEditingController(text: ' ');
    _initCrossword();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _openMobileKeyboard();
      }
    });
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  void _initCrossword() {
    _score = 0;
    _lives = 5;
    _grid = List.generate(gridSize, (_) => List.generate(gridSize, (_) => ''));
    _solution = List.generate(gridSize, (_) => List.generate(gridSize, (_) => ''));
    _cellNumbers = List.generate(gridSize, (_) => List.generate(gridSize, (_) => null));

    // Place clues in solution & cellNumbers
    for (var clue in _clues) {
      _cellNumbers[clue.startRow][clue.startCol] = clue.number;
      for (int i = 0; i < clue.answer.length; i++) {
        final r = clue.direction == 'across' ? clue.startRow : clue.startRow + i;
        final c = clue.direction == 'across' ? clue.startCol + i : clue.startCol;
        if (r < gridSize && c < gridSize) {
          _solution[r][c] = clue.answer[i];
        }
      }
    }

    _activeClue = _clues.first;
    _selectedRow = _activeClue!.startRow;
    _selectedCol = _activeClue!.startCol;
  }

  bool _isCellActive(int r, int c) {
    return _solution[r][c].isNotEmpty;
  }

  void _openMobileKeyboard() {
    _textEditingController.text = ' ';
    _textEditingController.selection = const TextSelection.collapsed(offset: 1);
    if (!_keyboardFocusNode.hasFocus) {
      _keyboardFocusNode.requestFocus();
    }
  }

  void _onKeyInput(String text) {
    if (text.isEmpty) {
      // User pressed backspace on the mobile software keyboard
      _onBackspace();
    } else {
      final clean = text.replaceAll(' ', '').trim();
      if (clean.isNotEmpty) {
        final lastChar = clean.characters.last.toUpperCase();
        if (RegExp(r'^[A-Z]$').hasMatch(lastChar)) {
          _onLetterInput(lastChar);
        }
      }
    }

    // Always reset controller back to single space so next keypress or backspace can be detected
    _textEditingController.text = ' ';
    _textEditingController.selection = const TextSelection.collapsed(offset: 1);
  }

  void _onLetterInput(String letter) {
    if (_selectedRow == null || _selectedCol == null) return;
    final r = _selectedRow!;
    final c = _selectedCol!;

    if (!_isCellActive(r, c)) return;

    setState(() {
      _grid[r][c] = letter;
      if (_solution[r][c] == letter) {
        _score += 20;
        GameAudioService.playCorrectDing();
      } else {
        _lives = (_lives - 1).clamp(0, 5);
        GameAudioService.playWrongBuzz();
      }

      // Automatically move forward along the active clue word
      if (_activeClue != null) {
        if (_activeClue!.direction == 'across') {
          for (int nextC = c + 1; nextC < gridSize; nextC++) {
            if (_isCellActive(r, nextC)) {
              _selectedCol = nextC;
              break;
            }
          }
        } else if (_activeClue!.direction == 'down') {
          for (int nextR = r + 1; nextR < gridSize; nextR++) {
            if (_isCellActive(nextR, c)) {
              _selectedRow = nextR;
              break;
            }
          }
        }
      }
    });

    _checkCompletion();
  }

  void _onBackspace() {
    if (_selectedRow == null || _selectedCol == null) return;
    final r = _selectedRow!;
    final c = _selectedCol!;

    GameAudioService.playKnifeSlice();

    setState(() {
      if (_grid[r][c].isNotEmpty) {
        _grid[r][c] = '';
      } else {
        // Move backward along active clue and clear previous cell
        if (_activeClue != null) {
          if (_activeClue!.direction == 'across' && c - 1 >= _activeClue!.startCol) {
            _selectedCol = c - 1;
            _grid[r][c - 1] = '';
          } else if (_activeClue!.direction == 'down' && r - 1 >= _activeClue!.startRow) {
            _selectedRow = r - 1;
            _grid[r - 1][c] = '';
          }
        }
      }
    });
  }

  void _checkCompletion() {
    bool allFilledAndCorrect = true;
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (_solution[r][c].isNotEmpty) {
          if (_grid[r][c] != _solution[r][c]) {
            allFilledAndCorrect = false;
            break;
          }
        }
      }
    }

    if (allFilledAndCorrect) {
      _showVictoryDialog();
    }
  }

  void _showVictoryDialog() {
    GameAudioService.playVictoryFanfare();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.stars_rounded, color: Colors.amber, size: 30),
            SizedBox(width: 8),
            Text('Crossword Solved! 🎉', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Excellent work! You solved all words and scored $_score XP!',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Continue', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Score & Lives Badge
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 16),
                const SizedBox(width: 4),
                Text('$_lives', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                const SizedBox(width: 10),
                const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 16),
                const SizedBox(width: 4),
                Text('$_score', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. 🌲 Real Treehouse Village Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_option5_treehouse_village.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF0F172A)),
            ),
          ),

          // 2. High-contrast gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.75),
                    Colors.black.withValues(alpha: 0.40),
                    Colors.black.withValues(alpha: 0.78),
                  ],
                ),
              ),
            ),
          ),

          // 3. Hidden 1x1 TextField to capture mobile system keyboard input
          Positioned(
            left: 0,
            top: 0,
            child: SizedBox(
              width: 1,
              height: 1,
              child: Opacity(
                opacity: 0.001,
                child: TextField(
                  focusNode: _keyboardFocusNode,
                  controller: _textEditingController,
                  autofocus: false,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  enableSuggestions: false,
                  onChanged: _onKeyInput,
                ),
              ),
            ),
          ),

          // 4. Main interactive area
          SafeArea(
            child: Column(
              children: [
                // Active Clue Banner (Highlighted Question Box)
                if (_activeClue != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF1E3A8A).withValues(alpha: 0.94),
                          const Color(0xFF0F172A).withValues(alpha: 0.90),
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
                              const Icon(Icons.help_outline_rounded, color: Color(0xFF38BDF8), size: 13),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'CLUE ${_activeClue!.number} (${_activeClue!.direction.toUpperCase()})',
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
                          _activeClue!.clue,
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
                  ),

                // Crossword Grid
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: gridSize,
                            crossAxisSpacing: 5,
                            mainAxisSpacing: 5,
                          ),
                          itemCount: gridSize * gridSize,
                          itemBuilder: (context, index) {
                            final r = index ~/ gridSize;
                            final c = index % gridSize;
                            final isActive = _isCellActive(r, c);
                            final isSelected = _selectedRow == r && _selectedCol == c;
                            final cellNum = _cellNumbers[r][c];
                            final letter = _grid[r][c];

                            if (!isActive) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              );
                            }

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  // Toggle direction if tapping the already selected cell
                                  if (_selectedRow == r && _selectedCol == c && _activeClue != null) {
                                    final otherClue = _clues.where((clue) {
                                      if (clue.direction == _activeClue!.direction) return false;
                                      if (clue.direction == 'across') {
                                        return clue.startRow == r && c >= clue.startCol && c < clue.startCol + clue.answer.length;
                                      } else {
                                        return clue.startCol == c && r >= clue.startRow && r < clue.startRow + clue.answer.length;
                                      }
                                    }).firstOrNull;
                                    if (otherClue != null) {
                                      _activeClue = otherClue;
                                    }
                                  } else {
                                    _selectedRow = r;
                                    _selectedCol = c;
                                    // Prioritize current direction match
                                    _CrosswordClue? match;
                                    for (var clue in _clues) {
                                      if (_activeClue != null && clue.direction == _activeClue!.direction) {
                                        if (clue.direction == 'across' && clue.startRow == r && c >= clue.startCol && c < clue.startCol + clue.answer.length) {
                                          match = clue;
                                          break;
                                        } else if (clue.direction == 'down' && clue.startCol == c && r >= clue.startRow && r < clue.startRow + clue.answer.length) {
                                          match = clue;
                                          break;
                                        }
                                      }
                                    }
                                    if (match == null) {
                                      for (var clue in _clues) {
                                        if (clue.direction == 'across' && clue.startRow == r && c >= clue.startCol && c < clue.startCol + clue.answer.length) {
                                          match = clue;
                                          break;
                                        } else if (clue.direction == 'down' && clue.startCol == c && r >= clue.startRow && r < clue.startRow + clue.answer.length) {
                                          match = clue;
                                          break;
                                        }
                                      }
                                    }
                                    if (match != null) _activeClue = match;
                                  }
                                });
                                _openMobileKeyboard();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFBFDBFE) : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                                    width: isSelected ? 2.6 : 1.2,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Stack(
                                  children: [
                                    if (cellNum != null)
                                      Positioned(
                                        top: 2,
                                        left: 3,
                                        child: Text(
                                          '$cellNum',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    Center(
                                      child: Text(
                                        letter,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: letter == _solution[r][c]
                                              ? const Color(0xFF16A34A)
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Clues Quick Navigation Row (Replaces the clunky on-screen virtual keyboard)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _clues.map((clue) {
                              final isCurrent = _activeClue == clue;
                              bool isSolved = true;
                              for (int i = 0; i < clue.answer.length; i++) {
                                final r = clue.direction == 'across' ? clue.startRow : clue.startRow + i;
                                final c = clue.direction == 'across' ? clue.startCol + i : clue.startCol;
                                if (_grid[r][c] != clue.answer[i]) {
                                  isSolved = false;
                                  break;
                                }
                              }

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _activeClue = clue;
                                      _selectedRow = clue.startRow;
                                      _selectedCol = clue.startCol;
                                    });
                                    _openMobileKeyboard();
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isCurrent
                                          ? const Color(0xFF2563EB)
                                          : (isSolved
                                              ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                              : const Color(0xFF1E293B)),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isCurrent
                                            ? const Color(0xFF60A5FA)
                                            : (isSolved
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFF334155)),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${clue.number} ${clue.direction.toUpperCase()}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            color: isCurrent || isSolved ? Colors.white : Colors.white70,
                                          ),
                                        ),
                                        if (isSolved) ...[
                                          const SizedBox(width: 4),
                                          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 13),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Tap to reopen mobile software keyboard anytime
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                        ),
                        child: IconButton(
                          tooltip: 'Open Keyboard',
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.keyboard_rounded, color: Color(0xFF38BDF8), size: 20),
                          onPressed: _openMobileKeyboard,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
