import 'package:flutter/material.dart';

import '../services/course_service.dart';
import '../theme/app_theme.dart';
import 'balloon_pop_screen.dart';
import 'chapter_content_screen.dart';
import 'fill_blanks_game_screen.dart';
import 'flashcard_game_screen.dart';
import 'flappy_word_screen.dart';
import 'highway_racer_screen.dart';
import 'match_game_screen.dart';
import 'mcq_game_screen.dart';
import 'word_ninja_screen.dart';

class LearnScreen extends StatefulWidget {
  final bool isActive;

  const LearnScreen({super.key, this.isActive = true});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  List<MobileCourseItem> _courses = [];
  bool _isLoading = true;
  String? _loadError;
  MobileCourseItem? _selectedCourse;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _loadCourses();
  }

  @override
  void didUpdateWidget(covariant LearnScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _loadCourses();
    }
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final list = await CourseService.getCourses();
      if (mounted) {
        setState(() {
          _courses = list;
          _isLoading = false;
          if (_selectedCourse == null && list.isNotEmpty) {
            _selectedCourse = list.first;
          }
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

  void _openCourseCurriculum(MobileCourseItem course) {
    setState(() {
      _selectedCourse = course;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_selectedCourse != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          setState(() {
            _selectedCourse = null;
          });
        },
        child: CourseCurriculumScreen(
          course: _selectedCourse!,
          onBack: () {
            setState(() {
              _selectedCourse = null;
            });
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: AppTheme.navBarGreen,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: AppTheme.navBarGreenBorder, width: 1.2),
        ),
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'My Courses',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF283548), width: 1),
            ),
            child: Row(
              children: [
                const Text('📚', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '${_courses.length} Courses',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFBBF24),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCourses,
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Course Curriculum 🎓',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Select a course below to explore all chapters, lessons and practice activities.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('📖', style: TextStyle(fontSize: 38)),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              const Text(
                'Available Courses',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Course Cards List
              if (_loadError != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          color: AppTheme.textMuted,
                          size: 36,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Could not load courses.\n$_loadError',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        TextButton(
                          onPressed: _loadCourses,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_courses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Text(
                      'No active courses are assigned to your account yet. Ask your admin to assign an active course and package to your school.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else
                ..._courses.map((course) => _buildCourseCard(course)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(MobileCourseItem course) {
    final Color courseColor = Color(course.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF161F38),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF283548), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: courseColor.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _openCourseCurriculum(course),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            courseColor.withValues(alpha: 0.2),
                            courseColor.withValues(alpha: 0.06),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: courseColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          course.icon,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${course.code}  ·  ${course.levelsCount} Levels  ·  ${course.chaptersCount} Chapters',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: courseColor,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: course.progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF1E293B),
                    valueColor: AlwaysStoppedAnimation<Color>(courseColor),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Text(
                      '${(course.progress * 100).round()}% Completed  ·  Explore Curriculum →',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: courseColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 📖 Course Curriculum Screen (All Levels & Chapters One by One Vertically)
// ============================================================================
class CourseCurriculumScreen extends StatefulWidget {
  final MobileCourseItem course;
  final VoidCallback? onBack;

  const CourseCurriculumScreen({super.key, required this.course, this.onBack});

  @override
  State<CourseCurriculumScreen> createState() => _CourseCurriculumScreenState();
}

class _CourseCurriculumScreenState extends State<CourseCurriculumScreen> {
  List<MobileLevel> _levels = [];
  bool _isLoading = true;
  String? _loadError;
  MobileChapter? _selectedChapter;
  String _selectedLevelName = '';
  final Set<int> _expandedLevelIndices = {};

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }

  Future<void> _loadCourseData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final levels = await CourseService.getCourseStructure(
        courseId: widget.course.id,
      );
      // Filter out any empty levels (no chapters)
      final activeLevels = levels.where((l) => l.chapters.isNotEmpty).toList();
      if (mounted) {
        setState(() {
          _levels = activeLevels;
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

  Color _getLevelColor(int index) {
    const colors = [
      Color(0xFF10B981), // Emerald
      Color(0xFF6366F1), // Indigo
      Color(0xFFF59E0B), // Amber
      Color(0xFFEC4899), // Pink
      Color(0xFF8B5CF6), // Purple for Gerunds
    ];
    return colors[index % colors.length];
  }

  void _navigateToChapter(MobileChapter chapter, String levelName) {
    setState(() {
      _selectedChapter = chapter;
      _selectedLevelName = levelName;
    });
  }





  @override
  Widget build(BuildContext context) {
    if (_selectedChapter != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          setState(() {
            _selectedChapter = null;
          });
        },
        child: ChapterContentScreen(
          chapter: _selectedChapter!,
          levelName: _selectedLevelName,
          onBack: () {
            setState(() {
              _selectedChapter = null;
            });
          },
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppTheme.textPrimary),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppTheme.textPrimary,
            ),
            onPressed: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            widget.course.name,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: const Color(0xFF161F38),
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
        title: Text(
          widget.course.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF283548), width: 1),
            ),
            child: Row(
              children: [
                const Text('📚', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  widget.course.code,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFBBF24),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCourseData,
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Summary Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF161F38),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF283548)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.course.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.layers_rounded,
                          size: 16,
                          color: Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_levels.length} Learning Levels',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Icon(
                          Icons.bolt_rounded,
                          size: 16,
                          color: Color(0xFFD97706),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '+250 Total XP',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Course Curriculum Levels',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  if (_levels.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${_levels.length} Learning Skills',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF818CF8),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              if (_loadError != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          color: AppTheme.textMuted,
                          size: 36,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Could not load this course.\n$_loadError',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        TextButton(
                          onPressed: _loadCourseData,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_levels.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No active levels are assigned to this course yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else ...[
                // ================================================================
                // 📋 EXPANDABLE CURRICULUM LEVELS (Accordion: Tap to expand/collapse)
                // ================================================================
                ...List.generate(_levels.length, (levelIndex) {
                  final level = _levels[levelIndex];
                  final levelColor = _getLevelColor(levelIndex);
                  final isExpanded = _expandedLevelIndices.contains(levelIndex);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 Interactive Level Header Bar (Matches Circled Box in Screenshot)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (_expandedLevelIndices.contains(levelIndex)) {
                                  _expandedLevelIndices.remove(levelIndex);
                                } else {
                                  _expandedLevelIndices.add(levelIndex);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF161F38),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isExpanded
                                      ? levelColor
                                      : levelColor.withValues(alpha: 0.45),
                                  width: isExpanded ? 2.0 : 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: levelColor.withValues(
                                      alpha: isExpanded ? 0.22 : 0.08,
                                    ),
                                    blurRadius: isExpanded ? 12 : 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Circular Level Badge
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: levelColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: levelColor.withValues(alpha: 0.35),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${levelIndex + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Level Name
                                  Expanded(
                                    child: Text(
                                      level.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isExpanded
                                            ? FontWeight.w800
                                            : FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),

                                  // Chapter Count Chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 3.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: levelColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${level.chapters.length} ${level.chapters.length == 1 ? 'Chapter' : 'Chapters'}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: levelColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Chevron Down / Up Indicator
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: isExpanded
                                          ? levelColor.withValues(alpha: 0.2)
                                          : const Color(0xFF1E293B),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      color: isExpanded
                                          ? levelColor
                                          : AppTheme.textSecondary,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // 🔹 Expandable Chapter Cards (Only visible when user taps to expand)
                        if (isExpanded) ...[
                          const SizedBox(height: 12),
                          if (level.chapters.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: const Color(0xFF161F38),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF283548)),
                              ),
                              child: Center(
                                child: Text(
                                  'No chapters available in ${level.name} yet.',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...level.chapters.map((chapter) {
                              return _buildChapterCard(
                                chapter,
                                levelColor,
                                level.name,
                              );
                            }),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _launchActivity(MobileActivityInfo activity, MobileChapter chapter) {
    Widget targetScreen;
    final title = '${chapter.name} - ${activity.title}';
    switch (activity.type) {
      case 'word_ninja':
        targetScreen = WordNinjaScreen(title: title);
        break;
      case 'car_racer':
        targetScreen = HighwayRacerScreen(title: title);
        break;
      case 'flappy_word':
        targetScreen = FlappyWordScreen(title: title);
        break;
      case 'balloon_pop':
        targetScreen = BalloonPopScreen(title: title);
        break;
      case 'flashcard':
        targetScreen = FlashcardGameScreen(title: title);
        break;
      case 'match':
        targetScreen = MatchGameScreen(title: title);
        break;
      case 'fill_blanks':
      case 'writing':
        targetScreen = FillBlanksGameScreen(title: title);
        break;
      case 'mcq':
      case 'space_defender':
      case 'crossword':
      case 'word_arrange':
      default:
        targetScreen = McqGameScreen(title: title);
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
    );
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'word_ninja':
        return const Color(0xFFE11D48); // Rose
      case 'car_racer':
        return const Color(0xFF0284C7); // Sky Blue
      case 'flappy_word':
        return const Color(0xFF0D9488); // Teal
      case 'balloon_pop':
        return const Color(0xFFD946EF); // Fuchsia
      case 'flashcard':
        return const Color(0xFFD97706); // Amber
      case 'match':
        return const Color(0xFF10B981); // Emerald
      case 'fill_blanks':
      case 'writing':
        return const Color(0xFF8B5CF6); // Purple
      case 'mcq':
      default:
        return const Color(0xFF6366F1); // Indigo
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'word_ninja':
        return Icons.sports_kabaddi_rounded;
      case 'car_racer':
        return Icons.directions_car_rounded;
      case 'flappy_word':
        return Icons.flutter_dash_rounded;
      case 'balloon_pop':
        return Icons.celebration_rounded;
      case 'flashcard':
        return Icons.style_rounded;
      case 'match':
        return Icons.extension_rounded;
      case 'fill_blanks':
        return Icons.edit_note_rounded;
      case 'writing':
        return Icons.border_color_rounded;
      case 'space_defender':
        return Icons.rocket_launch_rounded;
      case 'crossword':
        return Icons.grid_on_rounded;
      case 'mcq':
      default:
        return Icons.quiz_rounded;
    }
  }

  Widget _buildChapterCard(
    MobileChapter chapter,
    Color color,
    String levelName,
  ) {
    final bool isCompleted = chapter.progress >= 1.0;
    final double progress = chapter.progress;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF161F38),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: progress > 0
              ? color.withValues(alpha: 0.4)
              : const Color(0xFF283548),
          width: progress > 0 ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: progress > 0 ? 0.12 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chapter Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      isCompleted
                          ? Icons.check_circle_rounded
                          : (progress > 0
                                ? Icons.play_arrow_rounded
                                : Icons.menu_book_rounded),
                      color: color,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (chapter.description != null &&
                          chapter.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          chapter.description!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: const Color(0xFF1E293B),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${chapter.contents.length} Lessons • ${chapter.activities.length} Activities',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      size: 16,
                      color: Color(0xFFD97706),
                    ),
                    Text(
                      '+${chapter.activities.length * 50 + chapter.contents.length * 25} XP',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // 📖 MAPPED LESSONS & CONTENT SECTION
            if (chapter.contents.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFF283548)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.menu_book_rounded, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Lessons & Content (${chapter.contents.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...chapter.contents.map((content) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF283548)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.article_rounded, size: 16, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              content.title.isNotEmpty ? content.title : content.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              'Interactive Audio & Vocabulary Lesson',
                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _navigateToChapter(chapter, levelName),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Read', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            // 🎮 MAPPED ACTIVITIES & GAMES SECTION
            if (chapter.activities.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.sports_esports_rounded, size: 16, color: Color(0xFF6366F1)),
                  const SizedBox(width: 6),
                  Text(
                    'Practice Activities & Games (${chapter.activities.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...chapter.activities.map((act) {
                final actColor = _getActivityColor(act.type);
                final actIcon = _getActivityIcon(act.type);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF283548)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: actColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(actIcon, size: 18, color: actColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              act.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              act.subtitle,
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => _launchActivity(act, chapter),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: actColor,
                          side: BorderSide(color: actColor, width: 1.2),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Play', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            SizedBox(width: 4),
                            Icon(Icons.play_arrow_rounded, size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
