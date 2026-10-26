import 'package:flutter/material.dart';

class FillBlanksGameScreen extends StatefulWidget {
  final String title;

  const FillBlanksGameScreen({
    super.key,
    this.title = 'Fill in the Blanks: Sentence Builder',
  });

  @override
  State<FillBlanksGameScreen> createState() => _FillBlanksGameScreenState();
}

class _BlankQuestion {
  final String prompt;
  final String beforeBlank;
  final String afterBlank;
  final String correctWord;
  final List<String> choices;
  final String translation;

  _BlankQuestion({
    required this.prompt,
    required this.beforeBlank,
    required this.afterBlank,
    required this.correctWord,
    required this.choices,
    required this.translation,
  });
}

class _FillBlanksGameScreenState extends State<FillBlanksGameScreen> {
  int _score = 0;
  int _lives = 3;
  int _currentIndex = 0;
  String? _selectedWord;
  bool _answered = false;
  String _gameState = 'playing'; // 'playing', 'victory', 'gameover'

  final List<_BlankQuestion> _questions = [
    _BlankQuestion(
      prompt: 'Select the missing auxiliary verb:',
      beforeBlank: 'She',
      afterBlank: 'reading a fascinating novel right now.',
      correctWord: 'is',
      choices: ['is', 'are', 'were', 'have'],
      translation: 'She is reading a fascinating novel right now.',
    ),
    _BlankQuestion(
      prompt: 'Select the missing preposition:',
      beforeBlank: 'The meeting is scheduled',
      afterBlank: 'Monday morning at 10 AM.',
      correctWord: 'for',
      choices: ['for', 'at', 'into', 'from'],
      translation: 'The meeting is scheduled for Monday morning at 10 AM.',
    ),
    _BlankQuestion(
      prompt: 'Choose the correct comparative adjective:',
      beforeBlank: 'Mount Everest is',
      afterBlank: 'than any other mountain on Earth.',
      correctWord: 'taller',
      choices: ['taller', 'tallest', 'more tall', 'tall'],
      translation: 'Mount Everest is taller than any other mountain on Earth.',
    ),
    _BlankQuestion(
      prompt: 'Select the correct conjunction:',
      beforeBlank: 'He wanted to go outside,',
      afterBlank: 'it started raining heavily.',
      correctWord: 'but',
      choices: ['but', 'so', 'because', 'although'],
      translation: 'He wanted to go outside, but it started raining heavily.',
    ),
    _BlankQuestion(
      prompt: 'Choose the correct relative pronoun:',
      beforeBlank: 'The doctor',
      afterBlank: 'treated me was very polite and kind.',
      correctWord: 'who',
      choices: ['who', 'which', 'whose', 'whom'],
      translation: 'The doctor who treated me was very polite and kind.',
    ),
  ];

  void _chooseWord(String word) {
    if (_answered || _gameState != 'playing') return;

    final isCorrect = word == _questions[_currentIndex].correctWord;

    setState(() {
      _selectedWord = word;
      _answered = true;

      if (isCorrect) {
        _score += 100;
      } else {
        _lives--;
        if (_lives <= 0) {
          _gameState = 'gameover';
        }
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedWord = null;
        _answered = false;
      });
    } else {
      setState(() => _gameState = 'victory');
    }
  }

  void _restart() {
    setState(() {
      _score = 0;
      _lives = 3;
      _currentIndex = 0;
      _selectedWord = null;
      _answered = false;
      _gameState = 'playing';
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentIndex];

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

                      LinearProgressIndicator(
                        value: (_currentIndex + 1) / _questions.length,
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                        minHeight: 4,
                      ),

                      // Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Prompt badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF8B5CF6)),
                                ),
                                child: Text(
                                  q.prompt,
                                  style: const TextStyle(
                                    color: Color(0xFFA78BFA),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Interactive Sentence Box with Blank Slot
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Colors.white12, width: 1.5),
                                ),
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 8,
                                  children: [
                                    Text(
                                      q.beforeBlank,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    // Blank Slot
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _selectedWord == null
                                            ? Colors.white10
                                            : (_selectedWord == q.correctWord
                                                ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                                : const Color(0xFFEF4444).withValues(alpha: 0.2)),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _selectedWord == null
                                              ? const Color(0xFF8B5CF6)
                                              : (_selectedWord == q.correctWord
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFFEF4444)),
                                          width: 2,
                                        ),
                                      ),
                                      child: Text(
                                        _selectedWord ?? '_______',
                                        style: TextStyle(
                                          color: _selectedWord == null
                                              ? const Color(0xFFA78BFA)
                                              : (_selectedWord == q.correctWord
                                                  ? const Color(0xFF34D399)
                                                  : const Color(0xFFFCA5A5)),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      q.afterBlank,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),

                              const Text(
                                'Tap a word chip to place it in the blank:',
                                style: TextStyle(color: Colors.white60, fontSize: 13),
                              ),
                              const SizedBox(height: 14),

                              // Choices Chips
                              Wrap(
                                spacing: 10,
                                runSpacing: 12,
                                children: q.choices.map((choice) {
                                  final isChosen = _selectedWord == choice;
                                  final isCorrect = choice == q.correctWord;

                                  Color chipBg = const Color(0xFF1E293B);
                                  Color chipBorder = Colors.white24;
                                  Color textColor = Colors.white;

                                  if (_answered) {
                                    if (isCorrect) {
                                      chipBg = const Color(0xFF10B981);
                                      chipBorder = const Color(0xFF10B981);
                                      textColor = Colors.white;
                                    } else if (isChosen) {
                                      chipBg = const Color(0xFFEF4444);
                                      chipBorder = const Color(0xFFEF4444);
                                      textColor = Colors.white;
                                    }
                                  }

                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _answered ? null : () => _chooseWord(choice),
                                      borderRadius: BorderRadius.circular(14),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: chipBg,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: chipBorder, width: 1.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          choice,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                              // Feedback Box
                              if (_answered) ...[
                                const SizedBox(height: 24),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: _selectedWord == q.correctWord
                                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                        : const Color(0xFFEF4444).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _selectedWord == q.correctWord
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedWord == q.correctWord ? 'CORRECT! 🎯 +100 XP' : 'INCORRECT! ❌',
                                        style: TextStyle(
                                          color: _selectedWord == q.correctWord
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEF4444),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Full sentence: ${q.beforeBlank} ${q.correctWord} ${q.afterBlank}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _nextQuestion,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF8B5CF6),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    child: Text(
                                      _currentIndex < _questions.length - 1 ? 'Next Sentence ➡️' : 'See Results 🏆',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

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
            'CHALLENGE ${_currentIndex + 1}/${_questions.length}',
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
                '🎉 SENTENCE BUILDER COMPLETE!',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'All 5 blanks completed correctly!',
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
                onPressed: _restart,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Play Again', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
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
                'OUT OF LIVES!',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _restart,
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
