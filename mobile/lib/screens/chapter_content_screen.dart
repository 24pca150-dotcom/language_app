import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../services/content_service.dart';
import '../services/course_service.dart';
import '../theme/app_theme.dart';
import '../widgets/celebration_dialog.dart';
import 'balloon_pop_screen.dart';
import 'fill_blanks_game_screen.dart';
import 'flashcard_game_screen.dart';
import 'flappy_word_screen.dart';
import 'highway_racer_screen.dart';
import 'match_game_screen.dart';
import 'mcq_game_screen.dart';
import 'word_ninja_screen.dart';

class ChapterContentScreen extends StatefulWidget {
  final MobileChapter chapter;
  final String levelName;
  final VoidCallback? onBack;

  const ChapterContentScreen({
    super.key,
    required this.chapter,
    required this.levelName,
    this.onBack,
  });

  @override
  State<ChapterContentScreen> createState() => _ChapterContentScreenState();
}

class _ChapterContentScreenState extends State<ChapterContentScreen> {
  List<ChapterContentItem> _contents = [];
  int _activeContentIndex = 0;
  bool _isLoading = true;
  String? _loadError;
  final FlutterTts _textToSpeech = FlutterTts();
  bool _isSpeaking = false;
  String? _speakingText;
  int _speechRequestId = 0;
  late final Future<String?> _speechLanguage;

  @override
  void initState() {
    super.initState();
    _textToSpeech.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });
    _textToSpeech.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _speakingText = null;
        });
      }
    });
    _textToSpeech.setCancelHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _speakingText = null;
        });
      }
    });
    _textToSpeech.setErrorHandler((message) {
      if (!mounted) return;
      setState(() {
        _isSpeaking = false;
        _speakingText = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Text-to-speech error: $message')));
    });
    _speechLanguage = _configureSpeech();
    _loadContents();
  }

  Future<String?> _configureSpeech() async {
    await _textToSpeech.setSpeechRate(0.45);
    await _textToSpeech.setVolume(1.0);
    await _textToSpeech.awaitSpeakCompletion(false);

    for (final language in ['en-US', 'en-GB', 'en']) {
      if (await _textToSpeech.isLanguageAvailable(language) == true) {
        final result = await _textToSpeech.setLanguage(language);
        if (result == 1) return language;
      }
    }
    return null;
  }

  Future<void> _loadContents() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final list = await ContentService.getChapterContents(widget.chapter.id);
      if (mounted) {
        setState(() {
          _contents = list;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadError = error.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _playPronunciation(String word, String sound) async {
    final content = _contents[_activeContentIndex];
    final header =
        content.tableData.isNotEmpty && content.tableData.first.length > 1
        ? content.tableData.first[1].toLowerCase()
        : '';
    final text = (header.contains('sound produced') ? sound : word).trim();
    if (text.isEmpty) return;
    final speechText = text.replaceAll(RegExp(r'_+'), 'dash');

    if (_isSpeaking && _speakingText == text) {
      _speechRequestId++;
      await _textToSpeech.stop();
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _speakingText = null;
        });
      }
      return;
    }

    final requestId = ++_speechRequestId;
    setState(() {
      _isSpeaking = true;
      _speakingText = text;
    });

    try {
      await _textToSpeech.stop();
      final language = await _speechLanguage;
      if (!mounted || requestId != _speechRequestId) return;
      if (language == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No English voice is available. Install or enable a Text-to-Speech engine in device settings.',
            ),
          ),
        );
        setState(() {
          _isSpeaking = false;
          _speakingText = null;
        });
        return;
      }

      final result = await _textToSpeech.speak(speechText, focus: true);
      if (result != 1 && mounted && requestId == _speechRequestId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The device could not start speech playback. Check the TTS engine and media volume.',
            ),
          ),
        );
        setState(() {
          _isSpeaking = false;
          _speakingText = null;
        });
      }
    } on PlatformException catch (error) {
      if (mounted && requestId == _speechRequestId) {
        setState(() {
          _isSpeaking = false;
          _speakingText = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to play pronunciation: ${error.message ?? error.code}',
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _speechRequestId++;
    unawaited(_textToSpeech.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final currentContent = _contents.isNotEmpty
        ? _contents[_activeContentIndex]
        : null;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceWhite,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFF283548), width: 1.2),
        ),
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.levelName,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFFBBF24),
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.chapter.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          if (_contents.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    size: 16,
                    color: AppTheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_activeContentIndex + 1}/${_contents.length} Lessons',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      color: AppTheme.textMuted,
                      size: 36,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Could not load lesson content.\n$_loadError',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    TextButton(
                      onPressed: _loadContents,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            )
          : currentContent == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        size: 40,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Content Available Yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No lesson content has been added to this chapter in the database.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lesson Navigation Tabs if multiple contents
                  if (_contents.length > 1) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_contents.length, (idx) {
                          final isSelected = _activeContentIndex == idx;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                'Part ${idx + 1}: ${_contents[idx].name}',
                              ),
                              selected: isSelected,
                              onSelected: (_) =>
                                  setState(() => _activeContentIndex = idx),
                              selectedColor: AppTheme.primary,
                              backgroundColor: const Color(0xFF161F38),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : const Color(0xFF283548),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Content Hero Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.25),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'DATABASE LESSON #${currentContent.id}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.school_rounded,
                              color: Colors.white70,
                              size: 22,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currentContent.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Render Content Blocks
                  ...currentContent.blocks.map((b) => _buildBlock(b)),

                  // Render Table Content (e.g. 111 animal sounds or homophones)
                  if (currentContent.tableData.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Vocabulary & Sound Directory (Tap to Listen):',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(0, 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.boxColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.boxBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: currentContent.tableData.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                          itemBuilder: (context, idx) {
                            final row = currentContent.tableData[idx];
                            final isHeader = idx == 0;

                            if (isHeader) {
                              return Container(
                                color: const Color(0xFF1E293B),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        row.isNotEmpty ? row[0] : '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Color(0xFFFBBF24),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        row.length > 1 ? row[1] : '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Color(0xFFFBBF24),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 44,
                                      child: Center(
                                        child: Text(
                                          'Audio',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final word = row.isNotEmpty ? row[0] : '';
                            final soundOrMeaning = row.length > 1 ? row[1] : '';
                            final audioHeader =
                                currentContent.tableData.isNotEmpty &&
                                    currentContent.tableData.first.length > 1
                                ? currentContent.tableData.first[1]
                                      .toLowerCase()
                                : '';
                            final audioText =
                                audioHeader.contains('sound produced')
                                ? soundOrMeaning
                                : word;

                            return Material(
                              type: MaterialType.transparency,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                title: Text(
                                  word,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  soundOrMeaning,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      _isSpeaking &&
                                              _speakingText == audioText.trim()
                                          ? Icons.stop_rounded
                                          : Icons.volume_up_rounded,
                                      color: AppTheme.primary,
                                      size: 20,
                                    ),
                                    onPressed: () => _playPronunciation(
                                      word,
                                      soundOrMeaning,
                                    ),
                                  ),
                                ),
                                onTap: () =>
                                    _playPronunciation(word, soundOrMeaning),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Bottom Action Buttons
                  Row(
                    children: [
                      if (_activeContentIndex > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() => _activeContentIndex--);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Previous Part'),
                          ),
                        ),
                      if (_activeContentIndex > 0) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_activeContentIndex < _contents.length - 1) {
                              setState(() => _activeContentIndex++);
                            } else {
                              CourseService.completeChapter(widget.chapter.id);
                              CelebrationDialog.show(
                                context,
                                title: 'Chapter Completed! 🎉',
                                subtitle:
                                    'Awesome job! You mastered ${widget.chapter.name}!',
                                xpEarned: 50,
                                onContinue: () {
                                  if (widget.onBack != null) {
                                    widget.onBack!();
                                  } else if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                },
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _activeContentIndex < _contents.length - 1
                                ? 'Next Part →'
                                : 'Complete Chapter 🎉',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  void _launchActivity(String type, String title, Map<String, dynamic> data) {
    final lower = type.toLowerCase();
    if (lower.contains('flappy')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => FlappyWordScreen(title: title)));
    } else if (lower.contains('balloon')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => BalloonPopScreen(title: title)));
    } else if (lower.contains('ninja')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => WordNinjaScreen(title: title)));
    } else if (lower.contains('mcq')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => McqGameScreen(title: title)));
    } else if (lower.contains('match')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => MatchGameScreen(title: title)));
    } else if (lower.contains('flashcard')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => FlashcardGameScreen(title: title)));
    } else if (lower.contains('fill_blanks') || lower.contains('blank')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => FillBlanksGameScreen(title: title)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => HighwayRacerScreen(title: title)));
    }
  }

  Widget _buildBlock(ContentBlock block) {
    if (block.type == 'header') {
      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          block.data['text'] ?? '',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black54,
                blurRadius: 4,
                offset: Offset(0, 1.5),
              ),
            ],
          ),
        ),
      );
    } else if (block.type == 'paragraph') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161F38),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF283548)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            block.data['text'] ?? '',
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.6,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      );
    } else if (block.type == 'activity') {
      final actData = block.data;
      final title = actData['activityReferenceTitle'] ?? actData['title'] ?? 'Interactive Activity';
      final actType = (actData['activityReferenceType'] ?? actData['type'] ?? 'mcq').toString().toLowerCase();

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.sports_esports_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PRACTICE ACTIVITY', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _launchActivity(actType, title, actData),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              child: const Text('Play 🎮', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else if (block.type == 'list') {
      final items = block.data['items'] as List<dynamic>? ?? [];
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161F38),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF283548)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.map((it) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
                Expanded(child: Text(it.toString(), style: const TextStyle(fontSize: 14, height: 1.4, color: AppTheme.textPrimary))),
              ],
            ),
          )).toList(),
        ),
      );
    } else if (block.type == 'image') {
      final url = block.data['file']?['url'] ?? block.data['url'] ?? '';
      if (url.toString().isNotEmpty) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }
}
