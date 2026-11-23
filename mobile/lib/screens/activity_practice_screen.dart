import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../services/game_service.dart';
import '../theme/app_theme.dart';

// =============================================================================
// Helpers
// =============================================================================

/// Normalised activity type key, e.g. "fill-blanks" -> "fill_blanks".
String activityTypeKey(String type) {
  var t = type.toLowerCase().replaceAll('-', '_');
  if (t == 'multiple_choice') t = 'mcq';
  if (t == 'cloud_match') t = 'match';
  return t;
}

String activityTypeLabel(String key) {
  switch (key) {
    case 'mcq':
      return 'Multiple Choice';
    case 'match':
      return 'Match It';
    case 'fill_blanks':
      return 'Fill in the Blanks';
    case 'word_arrange':
      return 'Word Arrangement';
    case 'parts_of_speech':
      return 'Parts of Speech';
    case 'speaking':
      return 'Speaking';
    case 'sequencing':
      return 'Story Sequencing';
    default:
      return key.split('_').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
  }
}

IconData activityTypeIcon(String key) {
  switch (key) {
    case 'mcq':
      return Icons.quiz_rounded;
    case 'match':
      return Icons.extension_rounded;
    case 'fill_blanks':
      return Icons.edit_note_rounded;
    case 'word_arrange':
      return Icons.sort_by_alpha_rounded;
    case 'parts_of_speech':
      return Icons.label_rounded;
    case 'speaking':
      return Icons.mic_rounded;
    case 'sequencing':
      return Icons.format_list_numbered_rounded;
    default:
      return Icons.sports_esports_rounded;
  }
}

Color activityTypeColor(String key) {
  switch (key) {
    case 'mcq':
      return const Color(0xFF6366F1);
    case 'match':
      return const Color(0xFF10B981);
    case 'fill_blanks':
      return const Color(0xFF8B5CF6);
    case 'word_arrange':
      return const Color(0xFFEC4899);
    case 'parts_of_speech':
      return const Color(0xFF0EA5E9);
    case 'speaking':
      return const Color(0xFFF59E0B);
    case 'sequencing':
      return const Color(0xFF14B8A6);
    default:
      return const Color(0xFF475569);
  }
}

const _supportedTypes = {'mcq', 'match', 'fill_blanks', 'word_arrange', 'parts_of_speech', 'speaking', 'sequencing'};

/// Strips the simple HTML the admin editor stores (<strong>, <br>, &nbsp; ...).
String plainText(dynamic value) {
  final s = (value ?? '').toString();
  return s
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .trim();
}

/// MCQ / fill-in-the-blank activities may hold a pool of questions (`questions` / `sentences`).
/// Split each pool into one step per question, like the web player does.
List<MobileGameItem> expandQuestionPools(List<MobileGameItem> items) {
  final out = <MobileGameItem>[];
  for (final item in items) {
    final data = item.dataJson ?? const <String, dynamic>{};
    final key = activityTypeKey(item.type);
    final pool = key == 'mcq' ? data['questions'] : (key == 'fill_blanks' ? data['sentences'] : null);
    if (pool is List && pool.isNotEmpty) {
      for (final q in pool.whereType<Map>()) {
        out.add(item.copyWith(dataJson: {...data, ...Map<String, dynamic>.from(q)}..remove(key == 'mcq' ? 'questions' : 'sentences')));
      }
    } else {
      out.add(item);
    }
  }
  return out;
}

/// False when an activity has nothing to answer (no options, pairs...), so Next is never locked.
bool isPlayableActivity(MobileGameItem item) {
  final data = item.dataJson ?? const <String, dynamic>{};
  bool hasList(String k) => data[k] is List && (data[k] as List).isNotEmpty;
  switch (activityTypeKey(item.type)) {
    case 'mcq':
      return hasList('options');
    case 'match':
      return hasList('pairs');
    case 'parts_of_speech':
      return hasList('parts');
    case 'word_arrange':
      return plainText(data['text']).isNotEmpty;
    case 'fill_blanks':
      return RegExp(r'\[(.*?)\]').hasMatch(plainText(data['text']));
    case 'speaking':
      return plainText(data['text'] ?? data['targetText']).isNotEmpty;
    case 'sequencing':
      return data['events'] is List && (data['events'] as List).length > 1;
    default:
      return false;
  }
}

Widget networkPicture(String rawUrl, {double size = 56}) {
  final url = GameService.resolveMediaUrl(rawUrl);
  if (url.isEmpty) return SizedBox(width: size, height: size);
  if (url.toLowerCase().split('?').first.endsWith('.svg')) {
    return SvgPicture.network(url, width: size, height: size, fit: BoxFit.contain);
  }
  return Image.network(
    url,
    width: size,
    height: size,
    fit: BoxFit.contain,
    errorBuilder: (_, _, _) => Icon(Icons.image_not_supported_outlined, size: size * 0.6, color: AppTheme.textMuted),
  );
}

// =============================================================================
// Screen 2: activity type groups inside a course
// =============================================================================

class GameCourseGroupsScreen extends StatelessWidget {
  final String courseName;
  final List<MobileGameItem> activities;

  /// Opens arcade games (car racer, word ninja...) that have their own game screens.
  final void Function(MobileGameItem game)? onOpenGame;

  /// All levels (Listening skill, Speaking skill...) for the "which level?" picker.
  final List<MobileLevelInfo> levels;

  const GameCourseGroupsScreen({super.key, required this.courseName, required this.activities, this.onOpenGame, this.levels = const []});

  void _openGroup(BuildContext context, String key, List<MobileGameItem> items) {
    if (!_supportedTypes.contains(key) && onOpenGame != null) {
      // Arcade games have their own screens: let the learner pick which one
      if (items.length == 1) {
        onOpenGame!(items.first);
      } else {
        _showPicker(
          context,
          title: activityTypeLabel(key),
          options: items.map((g) => (label: g.title, count: 0, onTap: () => onOpenGame!(g))).toList(),
        );
      }
      return;
    }

    // Group this game's questions by level; ask which level when there is more than one
    final byLevel = <int, List<MobileGameItem>>{};
    for (final item in items) {
      final ids = item.levelIds.isEmpty ? const [0] : item.levelIds;
      for (final id in ids) {
        byLevel.putIfAbsent(id, () => []).add(item);
      }
    }
    void start(String title, List<MobileGameItem> list) => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityPracticeScreen(title: title, items: expandQuestionPools(list)),
      ),
    );

    if (byLevel.length <= 1) {
      start(activityTypeLabel(key), items);
      return;
    }

    final order = {for (var i = 0; i < levels.length; i++) levels[i].id: i};
    final ids = byLevel.keys.toList()..sort((a, b) => (order[a] ?? 999).compareTo(order[b] ?? 999));
    String nameOf(int id) => id == 0
        ? 'Other'
        : levels
              .firstWhere(
                (l) => l.id == id,
                orElse: () => MobileLevelInfo(id: id, name: 'Level $id'),
              )
              .name;

    _showPicker(
      context,
      title: '${activityTypeLabel(key)} – Choose a level',
      options: ids
          .map(
            (id) => (
              label: nameOf(id),
              count: expandQuestionPools(byLevel[id]!).length,
              onTap: () => start('${activityTypeLabel(key)} · ${nameOf(id)}', byLevel[id]!),
            ),
          )
          .toList(),
    );
  }

  /// Colourful bottom sheet listing choices (levels or games).
  void _showPicker(BuildContext context, {required String title, required List<({String label, int count, VoidCallback onTap})> options}) {
    const palette = [Color(0xFF6366F1), Color(0xFFF59E0B), Color(0xFF10B981), Color(0xFFEC4899), Color(0xFF0EA5E9), Color(0xFF8B5CF6)];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(color: AppTheme.boxBorderStrong, borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final o = options[i];
                    final color = palette[i % palette.length];
                    return Material(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          o.onTap();
                        },
                        child: Ink(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(colors: [color, Color.lerp(color, Colors.black, 0.25)!]),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.white.withValues(alpha: 0.25),
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  o.label,
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                              ),
                              if (o.count > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFFBBF24), borderRadius: BorderRadius.circular(12)),
                                  child: Text(
                                    '${o.count} Q',
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12),
                                  ),
                                ),
                              const SizedBox(width: 6),
                              const Icon(Icons.play_circle_fill_rounded, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep the order the admin created them in (content order)
    final sorted = [...activities]..sort((a, b) => a.id.compareTo(b.id));
    final groups = <String, List<MobileGameItem>>{};
    for (final a in sorted) {
      groups.putIfAbsent(activityTypeKey(a.type), () => []).add(a);
    }
    final entries = groups.entries.toList();

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            SafeArea(
              child: CustomScrollView(
                slivers: [
                  // ---------- Header: back + mascot + course name + count ----------
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 10, 16, 6),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
                            onPressed: () => Navigator.pop(context),
                          ),
                          SizedBox(width: 44, height: 44, child: Image.asset('assets/images/mascot.png', fit: BoxFit.contain)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  courseName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                                ),
                                const Text(
                                  'Games Arena',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF818CF8)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceWhite,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.boxBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.sports_esports_rounded, size: 16, color: Color(0xFF38BDF8)),
                                const SizedBox(width: 4),
                                Text(
                                  '${entries.length}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                      child: Text(
                        'Pick a game to play 🎮',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  if (entries.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text('No activities in this course yet.', style: TextStyle(color: AppTheme.textSecondary)),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.74,
                        ),
                        delegate: SliverChildBuilderDelegate((context, i) {
                          final e = entries[i];
                          return _GameTypeCard(
                            typeKey: e.key,
                            count: _supportedTypes.contains(e.key) ? expandQuestionPools(e.value).length : e.value.length,
                            coverUrl: gameCoverOf(e.value),
                            onTap: () => _openGroup(context, e.key, e.value),
                          );
                        }, childCount: entries.length),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Falling snow & stars animation
// =============================================================================

class _Flake {
  double x; // 0..1 across the screen
  double y; // 0..1 down the screen
  final double size;
  final double speed; // screen heights per second
  final double drift; // sideways sway amount
  final double phase;
  final bool isStar;
  final Color color;

  _Flake(this.x, this.y, this.size, this.speed, this.drift, this.phase, this.isStar, this.color);
}

/// Gentle snowflakes and twinkling stars drifting down inside their box.
class FallingStarsOverlay extends StatefulWidget {
  final int count;
  final double starRatio; // 0 = only snow, 1 = only stars
  final double speedScale;
  const FallingStarsOverlay({super.key, this.count = 14, this.starRatio = 0.4, this.speedScale = 1.0});

  @override
  State<FallingStarsOverlay> createState() => _FallingStarsOverlayState();
}

class _FallingStarsOverlayState extends State<FallingStarsOverlay> with SingleTickerProviderStateMixin {
  static const _starColors = [Color(0xFFFDE68A), Color(0xFFFBBF24), Color(0xFFF9A8D4), Color(0xFF93C5FD), Colors.white];
  final _random = Random();
  late final List<_Flake> _flakes;
  late final AnimationController _controller;
  Duration _last = Duration.zero;
  double _time = 0;

  @override
  void initState() {
    super.initState();
    _flakes = List.generate(widget.count, (_) => _newFlake(randomY: true));
    _controller = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_tick)
      ..forward();
  }

  _Flake _newFlake({bool randomY = false}) {
    final isStar = _random.nextDouble() < widget.starRatio;
    return _Flake(
      _random.nextDouble(),
      randomY ? _random.nextDouble() : -0.05,
      isStar ? 4 + _random.nextDouble() * 5 : 1.5 + _random.nextDouble() * 2.5,
      (0.04 + _random.nextDouble() * 0.08) * widget.speedScale,
      0.01 + _random.nextDouble() * 0.03,
      _random.nextDouble() * pi * 2,
      isStar,
      isStar ? _starColors[_random.nextInt(_starColors.length)] : Colors.white,
    );
  }

  void _tick() {
    final now = _controller.lastElapsedDuration ?? Duration.zero;
    final dt = ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    _time += dt;
    for (var i = 0; i < _flakes.length; i++) {
      final f = _flakes[i];
      f.y += f.speed * dt;
      if (f.y > 1.05) _flakes[i] = _newFlake();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(painter: _FlakePainter(_flakes, _time), size: Size.infinite),
    );
  }
}

class _FlakePainter extends CustomPainter {
  final List<_Flake> flakes;
  final double time;
  _FlakePainter(this.flakes, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in flakes) {
      final dx = (f.x + sin(time * 1.2 + f.phase) * f.drift) * size.width;
      final dy = f.y * size.height;
      final twinkle = 0.55 + 0.45 * sin(time * 3 + f.phase);
      final paint = Paint()..color = f.color.withValues(alpha: f.isStar ? twinkle : 0.75);

      if (!f.isStar) {
        canvas.drawCircle(Offset(dx, dy), f.size, paint);
        continue;
      }
      // Soft glow + 4-point sparkle star, slowly spinning
      canvas.drawCircle(Offset(dx, dy), f.size * 1.4, Paint()..color = f.color.withValues(alpha: 0.18 * twinkle));
      final s = f.size;
      final path = Path()
        ..moveTo(0, -s)
        ..lineTo(s * 0.28, -s * 0.28)
        ..lineTo(s, 0)
        ..lineTo(s * 0.28, s * 0.28)
        ..lineTo(0, s)
        ..lineTo(-s * 0.28, s * 0.28)
        ..lineTo(-s, 0)
        ..lineTo(-s * 0.28, -s * 0.28)
        ..close();
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(time * 0.6 + f.phase);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FlakePainter oldDelegate) => true;
}

/// The game's picture = the cover image the admin set on its activities
/// (the most recently added one wins, so a new upload shows straight away).
String gameCoverOf(List<MobileGameItem> items) {
  final sorted = [...items]..sort((a, b) => a.id.compareTo(b.id));
  return sorted.map((a) => a.coverImage ?? '').lastWhere((url) => url.isNotEmpty, orElse: () => '');
}

/// Admin-uploaded game picture. No picture → a plain colour gradient (no built-in images).
Widget gameCoverPicture(String url, Color color) {
  final fallback = DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.lerp(color, Colors.white, 0.15)!, Color.lerp(color, Colors.black, 0.55)!],
      ),
    ),
  );
  if (url.isEmpty) return fallback;
  if (url.toLowerCase().split('?').first.endsWith('.svg')) {
    return SvgPicture.network(url, fit: BoxFit.cover, placeholderBuilder: (_) => fallback);
  }
  return Image.network(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback);
}

/// How much of each game's falling effect is stars vs snow (rest is snow).
double _starRatioFor(String typeKey) {
  switch (typeKey) {
    case 'mcq':
    case 'speaking':
    case 'match':
      return 0.85; // starry night / sparkles
    case 'parts_of_speech':
    case 'space_defender':
      return 0.6; // fireflies & stars
    case 'word_arrange':
    case 'fill_blanks':
    case 'flappy_word':
      return 0.15; // mostly snow
    default:
      return 0.4;
  }
}

/// Colourful picture card for one activity type, with a press-down bounce.
class _GameTypeCard extends StatefulWidget {
  final String typeKey;
  final int count;
  final String coverUrl; // Admin-uploaded picture; empty = colour gradient
  final VoidCallback onTap;

  const _GameTypeCard({required this.typeKey, required this.count, required this.onTap, this.coverUrl = ''});

  @override
  State<_GameTypeCard> createState() => _GameTypeCardState();
}

class _GameTypeCardState extends State<_GameTypeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = activityTypeColor(widget.typeKey);
    final label = activityTypeLabel(widget.typeKey);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withValues(alpha: 0.9), width: 2),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                gameCoverPicture(widget.coverUrl, color),
                // ❄️⭐ Snow / stars falling inside this game's box (each game its own mix)
                Positioned.fill(
                  child: IgnorePointer(child: FallingStarsOverlay(count: 16, starRatio: _starRatioFor(widget.typeKey), speedScale: 1.8)),
                ),
                // Colour wash + dark bottom so the text is readable
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [color.withValues(alpha: 0.10), Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
                // Type icon (top-left)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6)],
                    ),
                    child: Icon(activityTypeIcon(widget.typeKey), color: Colors.white, size: 18),
                  ),
                ),
                // Question count (top-right)
                Positioned(
                  top: 12,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFFBBF24), borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      '${widget.count} Q',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                  ),
                ),
                // Title + Play (bottom)
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          height: 1.15,
                          shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.count} ${widget.count == 1 ? 'Question' : 'Questions'}',
                        style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [color, Color.lerp(color, Colors.white, 0.25)!]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Play',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Screen 3: play every question of one type with Next / Next
// =============================================================================

class ActivityPracticeScreen extends StatefulWidget {
  final String title;
  final List<MobileGameItem> items;

  const ActivityPracticeScreen({super.key, required this.title, required this.items});

  @override
  State<ActivityPracticeScreen> createState() => _ActivityPracticeScreenState();
}

class _ActivityPracticeScreenState extends State<ActivityPracticeScreen> {
  final FlutterTts _tts = FlutterTts();
  int _index = 0;
  int _correctCount = 0;
  bool _answered = false;
  bool? _lastCorrect;
  bool _finished = false;
  late final String _coverUrl = gameCoverOf(widget.items);

  @override
  void initState() {
    super.initState();
    _tts.setSpeechRate(0.42);
    _tts.setLanguage('en-US');
  }

  @override
  void dispose() {
    _tts.stop();
    if (_correctCount > 0) {
      GameService.recordActivity(
        'practice',
        score: ((_correctCount / widget.items.length) * 100).round().clamp(1, 100),
        count: _correctCount,
      );
    }
    super.dispose();
  }

  void _speak(String text) {
    _tts.stop();
    _tts.speak(text);
  }

  void _onAnswered(bool correct) {
    if (_answered) return;
    setState(() {
      _answered = true;
      _lastCorrect = correct;
      if (correct) _correctCount++;
    });
  }

  void _next() {
    _tts.stop();
    if (_index + 1 >= widget.items.length) {
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _index++;
      _answered = false;
      _lastCorrect = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items.length;
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        title: Text(
          widget.title,
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w800, fontSize: 17),
        ),
        actions: [
          if (!_finished)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_index + 1} / $total',
                  style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // The game's own picture as the background, dimmed so questions stay readable
          if (_coverUrl.isNotEmpty) ...[
            gameCoverPicture(_coverUrl, AppTheme.primary),
            Container(color: AppTheme.bgLight.withValues(alpha: 0.82)),
          ] else
            Container(decoration: BoxDecoration(gradient: AppTheme.backgroundGradient)),
          SafeArea(child: _finished ? _buildFinished() : _buildQuestion()),
        ],
      ),
    );
  }

  Widget _buildFinished() {
    final total = widget.items.length;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(
              'Super! All done',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('You got $_correctCount of $total correct', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(14),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                _index = 0;
                _correctCount = 0;
                _answered = false;
                _lastCorrect = null;
                _finished = false;
              }),
              child: const Text('Play Again 🔄'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    final item = widget.items[_index];
    final data = item.dataJson ?? {};
    final key = activityTypeKey(item.type);
    final explanation = plainText(data['explanation']);

    Widget body;
    switch (isPlayableActivity(item) ? key : '') {
      case 'mcq':
        body = _McqView(key: ValueKey('q$_index'), data: data, onAnswered: _onAnswered, speak: _speak);
        break;
      case 'word_arrange':
        body = _WordArrangeView(key: ValueKey('q$_index'), data: data, onAnswered: _onAnswered, speak: _speak);
        break;
      case 'parts_of_speech':
        body = _PartsOfSpeechView(key: ValueKey('q$_index'), data: data, onAnswered: _onAnswered);
        break;
      case 'match':
        body = _MatchView(key: ValueKey('q$_index'), data: data, onAnswered: _onAnswered, speak: _speak);
        break;
      case 'fill_blanks':
        body = _FillBlanksView(key: ValueKey('q$_index'), data: data, onAnswered: _onAnswered, speak: _speak);
        break;
      case 'sequencing':
        body = _SequencingView(key: ValueKey('q$_index'), data: data, onAnswered: _onAnswered, speak: _speak);
        break;
      case 'speaking':
        body = _SpeakingView(key: ValueKey('q$_index'), data: data, onAnswered: _onAnswered, speak: _speak);
        break;
      default:
        body = _card(
          Text(
            _supportedTypes.contains(key)
                ? 'This question has no content yet. Tap Next to continue.'
                : 'This activity type is not available on mobile yet.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        );
    }

    final canGoNext = _answered || !_supportedTypes.contains(key) || !isPlayableActivity(item);
    return Column(
      children: [
        LinearProgressIndicator(
          value: (_index + 1) / widget.items.length,
          minHeight: 5,
          backgroundColor: AppTheme.boxBorder,
          color: AppTheme.accent,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                body,
                if (_answered && _lastCorrect != null) ...[const SizedBox(height: 14), _feedback(_lastCorrect!, explanation)],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.black,
                disabledBackgroundColor: AppTheme.boxBorder,
                padding: const EdgeInsets.all(14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: canGoNext ? _next : null,
              icon: Icon(_index + 1 >= widget.items.length ? Icons.flag_rounded : Icons.arrow_forward_rounded),
              label: Text(
                _index + 1 >= widget.items.length ? 'Finish' : 'Next',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _feedback(bool correct, String explanation) {
    final color = correct ? AppTheme.secondary : AppTheme.danger;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            correct ? '✅ Correct! Good job!' : '❌ Not quite!',
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15),
          ),
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(explanation, style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
          ],
        ],
      ),
    );
  }
}

Widget _card(Widget child) => Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: AppTheme.surfaceWhite,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: AppTheme.boxBorder),
  ),
  child: child,
);

Widget _questionText(String text) => Text(
  text,
  style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700, height: 1.4),
);

Widget _listenButton(VoidCallback onTap, {String label = 'Listen'}) => Align(
  alignment: Alignment.centerLeft,
  child: OutlinedButton.icon(
    onPressed: onTap,
    icon: const Icon(Icons.volume_up_rounded, size: 18),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      foregroundColor: AppTheme.primary,
      side: const BorderSide(color: AppTheme.primary),
    ),
  ),
);

Widget _choiceButton({required String text, required VoidCallback? onTap, Color? fill, Color? border, Widget? leading}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: fill ?? AppTheme.boxColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border ?? AppTheme.boxBorderStrong, width: 1.6),
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading, const SizedBox(width: 10)],
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ------------------------------- MCQ -----------------------------------------
class _McqView extends StatefulWidget {
  final Map<String, dynamic> data;
  final void Function(bool) onAnswered;
  final void Function(String) speak;
  const _McqView({super.key, required this.data, required this.onAnswered, required this.speak});

  @override
  State<_McqView> createState() => _McqViewState();
}

class _McqViewState extends State<_McqView> {
  int? _selected;

  List<Map<String, dynamic>> get _options =>
      ((widget.data['options'] as List?) ?? []).whereType<Map>().map((o) => Map<String, dynamic>.from(o)).toList();

  bool _isCorrect(Map<String, dynamic> o) => o['is_correct'] == true || o['isCorrect'] == true || o['is_correct'] == 1;

  @override
  Widget build(BuildContext context) {
    final question = plainText(widget.data['question']);
    final audio = plainText(widget.data['audioText']).isNotEmpty
        ? plainText(widget.data['audioText'])
        : question.replaceAll(RegExp(r'_{2,}'), ' blank ');
    final image = (widget.data['imageUrl'] ?? '').toString();
    final options = _options;

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _listenButton(() => widget.speak(audio)),
          const SizedBox(height: 12),
          if (image.isNotEmpty) ...[Center(child: networkPicture(image, size: 120)), const SizedBox(height: 12)],
          _questionText(question),
          const SizedBox(height: 16),
          ...List.generate(options.length, (i) {
            final o = options[i];
            final answered = _selected != null;
            final correct = _isCorrect(o);
            Color? border;
            Color? fill;
            if (answered && correct) {
              border = AppTheme.secondary;
              fill = AppTheme.secondary.withValues(alpha: 0.15);
            } else if (answered && _selected == i) {
              border = AppTheme.danger;
              fill = AppTheme.danger.withValues(alpha: 0.15);
            }
            return _choiceButton(
              text: plainText(o['text']),
              fill: fill,
              border: border,
              leading: CircleAvatar(
                radius: 13,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                child: Text(
                  String.fromCharCode(65 + i),
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              onTap: answered
                  ? null
                  : () {
                      setState(() => _selected = i);
                      widget.onAnswered(correct);
                    },
            );
          }),
        ],
      ),
    );
  }
}

// --------------------------- Word Arrangement --------------------------------
class _WordArrangeView extends StatefulWidget {
  final Map<String, dynamic> data;
  final void Function(bool) onAnswered;
  final void Function(String) speak;
  const _WordArrangeView({super.key, required this.data, required this.onAnswered, required this.speak});

  @override
  State<_WordArrangeView> createState() => _WordArrangeViewState();
}

class _WordArrangeViewState extends State<_WordArrangeView> {
  late final List<String> _correct;
  late final List<int> _pool; // indexes into _correct, shuffled
  final List<int> _picked = [];
  bool _checked = false;
  bool _isRight = false;

  @override
  void initState() {
    super.initState();
    final text = plainText(widget.data['text']);
    _correct = (text.contains('/') ? text.split('/') : text.split(RegExp(r'\s+'))).map((w) => w.trim()).where((w) => w.isNotEmpty).toList();
    _pool = List.generate(_correct.length, (i) => i)..shuffle(Random());
  }

  void _check() {
    final user = _picked.map((i) => _correct[i]).join(' ').toLowerCase();
    final right = _correct.join(' ').toLowerCase();
    setState(() {
      _checked = true;
      _isRight = user == right;
    });
    widget.onAnswered(_isRight);
  }

  Widget _chip(String text, VoidCallback? onTap, Color color) => Padding(
    padding: const EdgeInsets.all(4),
    child: ActionChip(
      label: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
      ),
      backgroundColor: color,
      side: BorderSide.none,
      onPressed: onTap,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final sentence = _correct.join(' ');
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _questionText(
            plainText(widget.data['question']).isNotEmpty ? plainText(widget.data['question']) : 'Arrange the words to make a sentence.',
          ),
          const SizedBox(height: 14),
          Container(
            constraints: const BoxConstraints(minHeight: 70),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _checked ? (_isRight ? AppTheme.secondary : AppTheme.danger) : AppTheme.boxBorderStrong,
                width: 1.6,
              ),
            ),
            child: _picked.isEmpty
                ? Center(
                    child: Text('Tap the words below', style: TextStyle(color: AppTheme.textMuted)),
                  )
                : Wrap(
                    children: _picked
                        .map((i) => _chip(_correct[i], _checked ? null : () => setState(() => _picked.remove(i)), AppTheme.primary))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 14),
          Wrap(
            children: _pool
                .where((i) => !_picked.contains(i))
                .map((i) => _chip(_correct[i], _checked ? null : () => setState(() => _picked.add(i)), const Color(0xFFEC4899)))
                .toList(),
          ),
          const SizedBox(height: 14),
          if (!_checked)
            ElevatedButton(
              onPressed: _picked.length == _correct.length ? _check : null,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              child: const Text('Check', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          else ...[
            Text(
              'Answer: $sentence',
              style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _listenButton(() => widget.speak(sentence), label: 'Listen & read aloud'),
          ],
        ],
      ),
    );
  }
}

// ---------------------------- Parts of Speech --------------------------------
class _PartsOfSpeechView extends StatefulWidget {
  final Map<String, dynamic> data;
  final void Function(bool) onAnswered;
  const _PartsOfSpeechView({super.key, required this.data, required this.onAnswered});

  @override
  State<_PartsOfSpeechView> createState() => _PartsOfSpeechViewState();
}

class _PartsOfSpeechViewState extends State<_PartsOfSpeechView> {
  static const _tags = ['Noun', 'Pronoun', 'Verb', 'Adjective', 'Adverb', 'Preposition', 'Conjunction', 'Interjection'];
  late final List<Map<String, String>> _parts;
  final Map<int, String> _chosen = {};
  int _active = 0;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _parts = ((widget.data['parts'] as List?) ?? [])
        .whereType<Map>()
        .map((p) => {'word': '${p['word'] ?? ''}', 'tag': '${p['tag'] ?? ''}'})
        .toList();
  }

  String _clean(String w) => w.toLowerCase().replaceAll(RegExp(r"[^\w']"), '');

  void _check() {
    final right = List.generate(
      _parts.length,
      (i) => (_chosen[i] ?? '').toLowerCase() == _parts[i]['tag']!.toLowerCase(),
    ).every((ok) => ok);
    setState(() => _checked = true);
    widget.onAnswered(right);
  }

  @override
  Widget build(BuildContext context) {
    final sentence = plainText(widget.data['text']);
    final targets = _parts.map((p) => _clean(p['word']!)).toList();

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            plainText(widget.data['question']).isNotEmpty ? plainText(widget.data['question']) : 'Choose the part of speech:',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: sentence.split(RegExp(r'\s+')).map((w) {
              final idx = targets.indexOf(_clean(w));
              final isTarget = idx >= 0;
              return GestureDetector(
                onTap: isTarget && !_checked ? () => setState(() => _active = idx) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: isTarget
                      ? BoxDecoration(
                          color: (_active == idx ? AppTheme.accent : AppTheme.primary).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border(bottom: BorderSide(color: _active == idx ? AppTheme.accent : AppTheme.primary, width: 2.5)),
                        )
                      : null,
                  child: Text(
                    w,
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 19, fontWeight: isTarget ? FontWeight.w800 : FontWeight.w500),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          ...List.generate(_parts.length, (i) {
            final chosen = _chosen[i];
            final ok = chosen != null && chosen.toLowerCase() == _parts[i]['tag']!.toLowerCase();
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '“${_parts[i]['word']}” →  ${chosen ?? '?'}${_checked ? (ok ? '  ✅' : '  ❌ (${_parts[i]['tag']})') : ''}',
                style: TextStyle(color: _active == i ? AppTheme.accent : AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15),
              ),
            );
          }),
          if (!_checked) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags
                  .map(
                    (t) => ChoiceChip(
                      label: Text(t),
                      selected: _chosen[_active] == t,
                      onSelected: (_) => setState(() {
                        _chosen[_active] = t;
                        if (_active + 1 < _parts.length && !_chosen.containsKey(_active + 1)) _active++;
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _chosen.length == _parts.length ? _check : null,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              child: const Text('Check', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}

// -------------------------------- Match --------------------------------------
class _MatchView extends StatefulWidget {
  final Map<String, dynamic> data;
  final void Function(bool) onAnswered;
  final void Function(String) speak;
  const _MatchView({super.key, required this.data, required this.onAnswered, required this.speak});

  @override
  State<_MatchView> createState() => _MatchViewState();
}

class _MatchViewState extends State<_MatchView> {
  late final List<Map<String, String>> _pairs;
  late final List<int> _rightOrder;
  final Set<int> _matched = {};
  int? _selectedLeft;
  int? _wrongRight;
  int _mistakes = 0;

  @override
  void initState() {
    super.initState();
    _pairs = ((widget.data['pairs'] as List?) ?? [])
        .whereType<Map>()
        .map(
          (p) => {
            'left': plainText(p['left']),
            'leftImage': '${p['leftImage'] ?? p['left_image'] ?? ''}',
            'right': plainText(p['right']),
            'rightImage': '${p['rightImage'] ?? p['right_image'] ?? ''}',
          },
        )
        .toList();
    _rightOrder = List.generate(_pairs.length, (i) => i)..shuffle(Random());
  }

  void _tapRight(int r) {
    if (_selectedLeft == null || _matched.contains(r)) return;
    if (_selectedLeft == r) {
      setState(() {
        _matched.add(r);
        _selectedLeft = null;
      });
      widget.speak(_pairs[r]['right']!);
      if (_matched.length == _pairs.length) widget.onAnswered(_mistakes == 0);
    } else {
      setState(() {
        _wrongRight = r;
        _mistakes++;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _wrongRight = null);
      });
    }
  }

  Widget _tile({
    required String text,
    required String image,
    required bool done,
    required bool active,
    required bool wrong,
    VoidCallback? onTap,
  }) {
    Color border = AppTheme.boxBorderStrong;
    if (done) border = AppTheme.secondary;
    if (active) border = AppTheme.accent;
    if (wrong) border = AppTheme.danger;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: done ? AppTheme.secondary.withValues(alpha: 0.15) : AppTheme.boxColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: done ? null : onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: 1.8),
            ),
            child: Row(
              children: [
                if (image.isNotEmpty) ...[networkPicture(image, size: 40), const SizedBox(width: 6)],
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _questionText(plainText(widget.data['question']).isNotEmpty ? plainText(widget.data['question']) : 'Match the pairs.'),
          const SizedBox(height: 6),
          Text('Tap a picture on the left, then its match on the right.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: List.generate(
                    _pairs.length,
                    (i) => _tile(
                      text: _pairs[i]['left']!,
                      image: _pairs[i]['leftImage']!,
                      done: _matched.contains(i),
                      active: _selectedLeft == i,
                      wrong: false,
                      onTap: () => setState(() => _selectedLeft = i),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: _rightOrder
                      .map(
                        (r) => _tile(
                          text: _pairs[r]['right']!,
                          image: _pairs[r]['rightImage']!,
                          done: _matched.contains(r),
                          active: false,
                          wrong: _wrongRight == r,
                          onTap: () => _tapRight(r),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
          Text(
            'Matched ${_matched.length} / ${_pairs.length}',
            style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ----------------------------- Fill in the Blanks ----------------------------
class _FillBlanksView extends StatefulWidget {
  final Map<String, dynamic> data;
  final void Function(bool) onAnswered;
  final void Function(String) speak;
  const _FillBlanksView({super.key, required this.data, required this.onAnswered, required this.speak});

  @override
  State<_FillBlanksView> createState() => _FillBlanksViewState();
}

class _FillBlanksViewState extends State<_FillBlanksView> {
  // "The [cat] is on the [mat|rug]." -> typed blank / choice blank (first option correct)
  final List<String> _segments = [];
  final List<List<String>> _blankOptions = [];
  final List<String> _answers = [];
  final List<String?> _given = [];
  final List<TextEditingController> _controllers = [];
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    final text = plainText(widget.data['text']);
    var last = 0;
    for (final m in RegExp(r'\[(.*?)\]').allMatches(text)) {
      _segments.add(text.substring(last, m.start));
      final raw = m.group(1) ?? '';
      final opts = raw.split(RegExp(r'[|/]')).map((o) => o.trim()).where((o) => o.isNotEmpty).toList();
      _answers.add(opts.isNotEmpty ? opts.first : raw.trim());
      _blankOptions.add(opts.length > 1 ? (List.of(opts)..shuffle(Random())) : []);
      _given.add(null);
      _controllers.add(TextEditingController());
      last = m.end;
    }
    _segments.add(text.substring(last));
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  String _valueOf(int i) => _blankOptions[i].isEmpty ? _controllers[i].text.trim() : (_given[i] ?? '');

  void _check() {
    final right = List.generate(_answers.length, (i) => _valueOf(i).toLowerCase() == _answers[i].toLowerCase()).every((ok) => ok);
    setState(() => _checked = true);
    widget.onAnswered(right);
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < _segments.length; i++) {
      if (_segments[i].isNotEmpty) {
        // A new line in the text (e.g. each speaker of a dialogue) starts a new row
        final lines = _segments[i].split('\n');
        for (var l = 0; l < lines.length; l++) {
          if (l > 0) children.add(const SizedBox(width: double.infinity, height: 6));
          if (lines[l].isNotEmpty) {
            children.add(Text(lines[l], style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, height: 1.8)));
          }
        }
      }
      if (i < _answers.length) {
        if (_blankOptions[i].isEmpty) {
          children.add(
            SizedBox(
              width: 110,
              child: TextField(
                controller: _controllers[i],
                enabled: !_checked,
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(isDense: true, hintText: '_____'),
              ),
            ),
          );
        } else {
          children.add(
            DropdownButton<String>(
              value: _given[i],
              hint: const Text('choose'),
              items: _blankOptions[i].map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
              onChanged: _checked ? null : (v) => setState(() => _given[i] = v),
            ),
          );
        }
      }
    }

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (plainText(widget.data['audioText']).isNotEmpty) ...[
            _listenButton(() => widget.speak(plainText(widget.data['audioText'])), label: 'Listen to the audio'),
            const SizedBox(height: 12),
          ],
          if (plainText(widget.data['question']).isNotEmpty) ...[
            _questionText(plainText(widget.data['question'])),
            const SizedBox(height: 10),
          ],
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: children),
          const SizedBox(height: 14),
          if (!_checked)
            ElevatedButton(
              onPressed: _check,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              child: const Text('Check', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          else
            Text(
              'Answer: ${_answers.join(', ')}',
              style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }
}

// ------------------------------ Sequencing -----------------------------------
class _SequencingView extends StatefulWidget {
  final Map<String, dynamic> data;
  final void Function(bool) onAnswered;
  final void Function(String) speak;
  const _SequencingView({super.key, required this.data, required this.onAnswered, required this.speak});

  @override
  State<_SequencingView> createState() => _SequencingViewState();
}

class _SequencingViewState extends State<_SequencingView> {
  late final List<String> _correct;
  late List<int> _order; // indexes into _correct, in the learner's order
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _correct = ((widget.data['events'] as List?) ?? []).map((e) => plainText(e)).where((e) => e.isNotEmpty).toList();
    _order = List.generate(_correct.length, (i) => i);
    // Shuffle until it differs from the answer
    for (var tries = 0; tries < 20; tries++) {
      _order.shuffle(Random());
      if (_correct.length < 2 || !List.generate(_order.length, (i) => _order[i] == i).every((ok) => ok)) break;
    }
  }

  void _move(int from, int to) {
    if (_checked || to < 0 || to >= _order.length) return;
    setState(() {
      final item = _order.removeAt(from);
      _order.insert(to, item);
    });
  }

  void _check() {
    final right = List.generate(_order.length, (i) => _order[i] == i).every((ok) => ok);
    setState(() => _checked = true);
    widget.onAnswered(right);
  }

  @override
  Widget build(BuildContext context) {
    final story = plainText(widget.data['audioText']);
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (story.isNotEmpty) ...[_listenButton(() => widget.speak(story), label: 'Listen to the story'), const SizedBox(height: 12)],
          _questionText(
            plainText(widget.data['question']).isNotEmpty ? plainText(widget.data['question']) : 'Arrange the events in the correct order.',
          ),
          const SizedBox(height: 6),
          Text('Use ▲ ▼ to move each event into its place.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          ...List.generate(_order.length, (pos) {
            final idx = _order[pos];
            final ok = _order[pos] == pos;
            final border = !_checked ? AppTheme.boxBorderStrong : (ok ? AppTheme.secondary : AppTheme.danger);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
              decoration: BoxDecoration(
                color: _checked ? border.withValues(alpha: 0.12) : AppTheme.boxColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border, width: 1.5),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: const Color(0xFF14B8A6),
                    child: Text(
                      '${pos + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _correct[idx],
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (!_checked)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(onTap: () => _move(pos, pos - 1), child: const Icon(Icons.keyboard_arrow_up_rounded, size: 26)),
                        InkWell(onTap: () => _move(pos, pos + 1), child: const Icon(Icons.keyboard_arrow_down_rounded, size: 26)),
                      ],
                    )
                  else
                    Padding(padding: const EdgeInsets.only(right: 6), child: Text(ok ? '✅' : '❌ ${idx + 1}')),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          if (!_checked)
            ElevatedButton(
              onPressed: _check,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              child: const Text('Check', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}

// ------------------------------- Speaking ------------------------------------
class _SpeakingView extends StatelessWidget {
  final Map<String, dynamic> data;
  final void Function(bool) onAnswered;
  final void Function(String) speak;
  const _SpeakingView({super.key, required this.data, required this.onAnswered, required this.speak});

  @override
  Widget build(BuildContext context) {
    final sentence = plainText(data['text'] ?? data['targetText']);
    final image = (data['media_url'] ?? data['imageUrl'] ?? '').toString();
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            plainText(data['question']).isNotEmpty ? plainText(data['question']) : 'Read the sentence aloud.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          if (image.isNotEmpty) ...[Center(child: networkPicture(image, size: 110)), const SizedBox(height: 12)],
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Text(
              sentence,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800, height: 1.4),
            ),
          ),
          const SizedBox(height: 14),
          _listenButton(() => speak(sentence), label: 'Listen first'),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => onAnswered(true),
            icon: const Icon(Icons.record_voice_over_rounded),
            label: const Text('I read it aloud ✓', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}
