import 'dart:async';
import 'package:flutter/material.dart';

class McqGameScreen extends StatefulWidget {
  final String title;

  const McqGameScreen({
    super.key,
    this.title = 'MCQ Arena: Rapid Grammar & Vocab',
  });

  @override
  State<McqGameScreen> createState() => _McqGameScreenState();
}

class _McqQuestion {
  final String question;
  final String category;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  _McqQuestion({
    required this.question,
    required this.category,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

class _McqGameScreenState extends State<McqGameScreen> {
  int _score = 0;
  int _lives = 3;
  int _streak = 0;
  int _currentIndex = 0;
  int? _selectedOption;
  bool _answered = false;
  int _timeLeft = 15;
  Timer? _countdownTimer;
  String _gameState = 'playing'; // 'playing', 'victory', 'gameover'

  final List<_McqQuestion> _questions = [
    _McqQuestion(
      question: 'Which of the following is an IRREGULAR past tense verb?',
      category: 'IRREGULAR VERBS',
      options: ['Walked', 'Played', 'Caught', 'Opened'],
      correctIndex: 2,
      explanation: '"Catch" becomes "Caught", which does not end in "-ed".',
    ),
    _McqQuestion(
      question: 'Choose the correct ANTONYM for the word "ANCIENT":',
      category: 'VOCABULARY & ANTONYMS',
      options: ['Historic', 'Modern', 'Antique', 'Prehistoric'],
      correctIndex: 1,
      explanation: '"Modern" means of the present time, opposite to "Ancient".',
    ),
    _McqQuestion(
      question: 'Identify the ADVERB in the sentence: "The cheetah ran exceptionally fast."',
      category: 'PARTS OF SPEECH',
      options: ['Cheetah', 'Ran', 'Exceptionally', 'Fast'],
      correctIndex: 2,
      explanation: '"Exceptionally" is an adverb modifying the adverb "fast".',
    ),
    _McqQuestion(
      question: 'Select the correct PLURAL form of the noun "CRISIS":',
      category: 'PLURAL NOUNS',
      options: ['Crisises', 'Crisis', 'Crises', 'Crisii'],
      correctIndex: 2,
      explanation: 'Greek origin nouns ending in "-is" become "-es" in plural: "Crises".',
    ),
    _McqQuestion(
      question: 'Complete with correct preposition: "She has been learning English ___ five years."',
      category: 'PREPOSITIONS & TENSES',
      options: ['Since', 'For', 'During', 'From'],
      correctIndex: 1,
      explanation: 'We use "for" to mention a duration/period of time ("for five years").',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startQuestionTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startQuestionTimer() {
    _countdownTimer?.cancel();
    _timeLeft = 15;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        if (mounted) setState(() => _timeLeft--);
      } else {
        _countdownTimer?.cancel();
        _handleTimeOut();
      }
    });
  }

  void _handleTimeOut() {
    if (_answered || _gameState != 'playing') return;
    setState(() {
      _answered = true;
      _selectedOption = -1; // timed out
      _streak = 0;
      _lives--;
      if (_lives <= 0) _gameState = 'gameover';
    });
  }

  void _selectOption(int index) {
    if (_answered || _gameState != 'playing') return;

    _countdownTimer?.cancel();
    final isCorrect = index == _questions[_currentIndex].correctIndex;

    setState(() {
      _selectedOption = index;
      _answered = true;

      if (isCorrect) {
        _streak++;
        final bonus = 100 + (_streak >= 2 ? _streak * 25 : 0);
        _score += bonus;
      } else {
        _streak = 0;
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
        _selectedOption = null;
        _answered = false;
      });
      _startQuestionTimer();
    } else {
      setState(() => _gameState = 'victory');
    }
  }

  void _restartGame() {
    setState(() {
      _score = 0;
      _lives = 3;
      _streak = 0;
      _currentIndex = 0;
      _selectedOption = null;
      _answered = false;
      _gameState = 'playing';
    });
    _startQuestionTimer();
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

                      // Timer Progress Bar
                      LinearProgressIndicator(
                        value: _timeLeft / 15.0,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _timeLeft > 5 ? const Color(0xFF38BDF8) : const Color(0xFFEF4444),
                        ),
                        minHeight: 4,
                      ),

                      // Question Body
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF6366F1)),
                                ),
                                child: Text(
                                  q.category,
                                  style: const TextStyle(
                                    color: Color(0xFF818CF8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Question Text
                              Text(
                                q.question,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // 4 Options
                              ...List.generate(q.options.length, (idx) {
                                return _buildOptionCard(idx, q.options[idx], q.correctIndex);
                              }),

                              // Explanation Box (if answered)
                              if (_answered) ...[
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: _selectedOption == q.correctIndex
                                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                        : const Color(0xFFEF4444).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _selectedOption == q.correctIndex
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            _selectedOption == q.correctIndex
                                                ? Icons.check_circle_rounded
                                                : Icons.cancel_rounded,
                                            color: _selectedOption == q.correctIndex
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFEF4444),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _selectedOption == q.correctIndex
                                                ? 'EXCELLENT! +100 XP'
                                                : 'INCORRECT!',
                                            style: TextStyle(
                                              color: _selectedOption == q.correctIndex
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFFEF4444),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        q.explanation,
                                        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
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
                                      backgroundColor: const Color(0xFF6366F1),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    child: Text(
                                      _currentIndex < _questions.length - 1 ? 'Next Question ➡️' : 'See Results 🏆',
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
              if (_streak >= 2) ...[
                const SizedBox(width: 8),
                Text('🔥 ${_streak}x', style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ],
          ),
          Text(
            'QUESTION ${_currentIndex + 1}/${_questions.length}',
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
              const SizedBox(width: 10),
              Text(
                '${_timeLeft}s',
                style: TextStyle(
                  color: _timeLeft > 5 ? const Color(0xFF38BDF8) : const Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(int index, String optionText, int correctIndex) {
    Color borderColor = Colors.white24;
    Color bgColor = const Color(0xFF0F172A);
    Color textColor = Colors.white;

    if (_answered) {
      if (index == correctIndex) {
        borderColor = const Color(0xFF10B981);
        bgColor = const Color(0xFF10B981).withValues(alpha: 0.25);
        textColor = const Color(0xFF6EE7B7);
      } else if (index == _selectedOption) {
        borderColor = const Color(0xFFEF4444);
        bgColor = const Color(0xFFEF4444).withValues(alpha: 0.25);
        textColor = const Color(0xFFFCA5A5);
      }
    }

    final letter = String.fromCharCode(65 + index); // A, B, C, D

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _answered ? null : () => _selectOption(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    optionText,
                    style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                if (_answered && index == correctIndex)
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22)
                else if (_answered && index == _selectedOption)
                  const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 22),
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
              const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 64),
              const SizedBox(height: 12),
              const Text(
                '🎉 MCQ ARENA CLEARED!',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'You solved all 5 questions with language precision!',
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
                  'Final Score: $_score XP',
                  style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _restartGame,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Play Again', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
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
              const SizedBox(height: 6),
              const Text(
                'Take your time to read the question rules carefully.',
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
                onPressed: _restartGame,
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
