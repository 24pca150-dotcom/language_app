import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/game_service.dart';
import '../data/game_question_bank.dart';
import '../services/game_audio_service.dart';

class McqGameScreen extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? dataJson;

  const McqGameScreen({
    super.key,
    this.title = 'MCQ Arena: Rapid Grammar & Vocab',
    this.dataJson,
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

class _McqGameScreenState extends State<McqGameScreen> with SingleTickerProviderStateMixin {
  int _score = 0;
  int _correctCount = 0;
  int _lives = 5;
  int _streak = 0;
  int _currentIndex = 0;
  int? _selectedOption;
  bool _answered = false;
  int _timeLeft = 15;
  Timer? _countdownTimer;
  String _gameState = 'playing'; // 'playing', 'victory', 'gameover'
  late AnimationController _swayController;

  final List<_McqQuestion> _questions = [];

  @override
  void initState() {
    super.initState();
    _swayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _setupQuestions();
    _startQuestionTimer();
  }

  void _setupQuestions() {
    _questions.clear();
    final dj = widget.dataJson;
    final List<_McqQuestion> dynamicList = [];

    if (dj != null) {
      if (dj['questions'] is List && (dj['questions'] as List).isNotEmpty) {
        for (var q in dj['questions']) {
          if (q is! Map<String, dynamic>) continue;
          final qText = (q['question'] ?? q['title'] ?? '').toString();
          final rawOptions = q['options'] as List<dynamic>? ?? [];
          final List<String> optTexts = [];
          int correct = 0;

          for (int i = 0; i < rawOptions.length; i++) {
            final opt = rawOptions[i];
            if (opt is Map<String, dynamic>) {
              optTexts.add((opt['text'] ?? opt['option'] ?? '').toString());
              if (opt['isCorrect'] == true || opt['is_correct'] == true || opt['correct'] == true) {
                correct = i;
              }
            } else {
              optTexts.add(opt.toString());
            }
          }

          if (qText.isNotEmpty && optTexts.isNotEmpty) {
            dynamicList.add(_McqQuestion(
              question: qText,
              category: (q['category'] ?? dj['title'] ?? 'EXERCISE').toString().toUpperCase(),
              options: optTexts,
              correctIndex: correct,
              explanation: (q['explanation'] ?? 'Great job!').toString(),
            ));
          }
        }
      } else if (dj['options'] is List && (dj['options'] as List).isNotEmpty) {
        final qText = (dj['question'] ?? dj['title'] ?? widget.title).toString();
        final rawOptions = dj['options'] as List<dynamic>;
        final List<String> optTexts = [];
        int correct = 0;

        for (int i = 0; i < rawOptions.length; i++) {
          final opt = rawOptions[i];
          if (opt is Map<String, dynamic>) {
            optTexts.add((opt['text'] ?? opt['option'] ?? '').toString());
            if (opt['isCorrect'] == true || opt['is_correct'] == true || opt['correct'] == true) {
              correct = i;
            }
          } else {
            optTexts.add(opt.toString());
          }
        }

        if (optTexts.isNotEmpty) {
          dynamicList.add(_McqQuestion(
            question: qText,
            category: (dj['category'] ?? 'QUIZ').toString().toUpperCase(),
            options: optTexts,
            correctIndex: correct,
            explanation: (dj['explanation'] ?? 'Correct answer!').toString(),
          ));
        }
      }
    }

    if (dynamicList.isNotEmpty) {
      dynamicList.shuffle();
      _questions.addAll(dynamicList.take(5));
    } else {
      final randomPool = GameQuestionBank.getRandomMcqQuestions(5);
      for (var q in randomPool) {
        _questions.add(_McqQuestion(
          question: q['question'] as String,
          category: q['category'] as String,
          options: List<String>.from(q['options'] as List),
          correctIndex: q['correctIndex'] as int,
          explanation: q['explanation'] as String,
        ));
      }
    }
  }

  @override
  void dispose() {
    _recordResult();
    _swayController.dispose();
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
        GameAudioService.playCorrectDing();
        _streak++;
        final bonus = 100 + (_streak >= 2 ? _streak * 25 : 0);
        _score += bonus;
        _correctCount++;
      } else {
        GameAudioService.playWrongBuzz();
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

  void _recordResult() {
    if (_correctCount <= 0) return;
    GameService.recordActivity('mcq', count: _correctCount);
  }

  void _restartGame() {
    _recordResult();
    _setupQuestions();
    setState(() {
      _score = 0;
      _correctCount = 0;
      _lives = 5;
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
                  // 1. 🌳 Real Banyan Tree Background (Tree Branches setting)
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/game_soon_banyan.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF1E293B)),
                    ),
                  ),

                  // 2. Forest Vignette Gradient for high text contrast
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.75),
                            Colors.black.withValues(alpha: 0.45),
                            Colors.black.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Tree Canopy Game Layout
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

                      // Tree Canopy Question Body
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Carved Parchment Question Plaque on Tree Trunk
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF2E1A0F), Color(0xFF1F120A)],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: const Color(0xFFD97706), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Category Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFD97706).withValues(alpha: 0.3),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFF59E0B)),
                                          ),
                                          child: Text(
                                            '🌿 ${q.category}',
                                            style: const TextStyle(
                                              color: Color(0xFFFDE68A),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ),
                                        const Row(
                                          children: [
                                            Icon(Icons.park_rounded, color: Color(0xFF4ADE80), size: 16),
                                            SizedBox(width: 4),
                                            Text(
                                              'TREE OF KNOWLEDGE',
                                              style: TextStyle(color: Color(0xFF86EFAC), fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Question Text
                                    Text(
                                      q.question,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17.5,
                                        fontWeight: FontWeight.bold,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

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
              if (_streak >= 2) ...[
                const SizedBox(width: 6),
                Text('🔥${_streak}x', style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Q${_currentIndex + 1}/${_questions.length}',
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
              Text(
                '${_timeLeft}s',
                style: TextStyle(
                  color: _timeLeft > 5 ? const Color(0xFF38BDF8) : const Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(int index, String optionText, int correctIndex) {
    final bool isCorrect = _answered && index == correctIndex;
    final bool isWrong = _answered && index == _selectedOption && _selectedOption != correctIndex;

    Color borderColor = const Color(0xFFB45309);
    List<Color> bgGradient = [const Color(0xFF2E1A0F), const Color(0xFF1B0E06)];
    Color textColor = Colors.white;

    if (_answered) {
      if (isCorrect) {
        borderColor = const Color(0xFF10B981);
        bgGradient = [const Color(0xFF065F46), const Color(0xFF047857)];
        textColor = const Color(0xFFD1FAE5);
      } else if (isWrong) {
        borderColor = const Color(0xFFEF4444);
        bgGradient = [const Color(0xFF7F1D1D), const Color(0xFF991B1B)];
        textColor = const Color(0xFFFEE2E2);
      }
    }

    final letter = String.fromCharCode(65 + index); // A, B, C, D

    return AnimatedBuilder(
      animation: _swayController,
      builder: (context, child) {
        // Subtle wind swaying pendulum physics
        final double sway = sin((_swayController.value * 2 * pi) + (index * 1.5)) * 0.032;
        return Transform.rotate(
          angle: sway,
          alignment: Alignment.topCenter,
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🌿 Hanging Ropes & Leaves from Tree Branch above
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Hanging Rope
                  Container(
                    width: 3.0,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 2)],
                    ),
                  ),
                  // Small Green Leaf
                  const Icon(Icons.eco_rounded, color: Color(0xFF4ADE80), size: 14),
                  // Right Hanging Rope
                  Container(
                    width: 3.0,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 2)],
                    ),
                  ),
                ],
              ),
            ),

            // 🪵 Carved Wooden Hanging Signboard
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: bgGradient,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 2.0),
                boxShadow: [
                  BoxShadow(
                    color: isCorrect
                        ? const Color(0xFF10B981).withValues(alpha: 0.5)
                        : isWrong
                            ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.6),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _answered ? null : () => _selectOption(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        // Golden Wood Coin with Option Letter
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF78350F),
                            border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                          ),
                          child: Center(
                            child: Text(
                              letter,
                              style: const TextStyle(
                                color: Color(0xFFFEF3C7),
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            optionText,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                              shadows: const [
                                Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black87),
                              ],
                            ),
                          ),
                        ),
                        if (isCorrect)
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 24)
                        else if (isWrong)
                          const Icon(Icons.cancel_rounded, color: Color(0xFFF87171), size: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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
