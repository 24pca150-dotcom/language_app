import 'package:flutter/material.dart';

import '../services/course_service.dart';
import '../theme/app_theme.dart';
import 'chapter_content_screen.dart';
import 'fill_blanks_game_screen.dart';
import 'match_game_screen.dart';
import 'mcq_game_screen.dart';

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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppTheme.navBarGreen,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: AppTheme.navBarGreenBorder, width: 1.2),
        ),
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF14361F)),
        title: const Text(
          'My Courses',
          style: TextStyle(
            color: Color(0xFF14361F),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('📚', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '${_courses.length} Courses',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: courseColor.withValues(alpha: 0.08),
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
                    backgroundColor: const Color(0xFFF1F5F9),
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
      if (mounted) {
        setState(() {
          _levels = levels;
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
    ];
    return colors[index % colors.length];
  }

  void _navigateToChapter(MobileChapter chapter, String levelName) {
    setState(() {
      _selectedChapter = chapter;
      _selectedLevelName = levelName;
    });
  }

  void _openLessonDialog(MobileChapter chapter, Color color, String levelName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewPadding.bottom;
        return Container(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            bottomInset > 0 ? bottomInset + 20 : 36,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                chapter.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                chapter.description ??
                    'Interactive lessons, examples, and practice tests.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.video_library_rounded,
                          color: color,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${chapter.contentsCount} Interactive Learning Contents',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.assignment_turned_in_rounded,
                          color: AppTheme.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${chapter.assessmentsCount} Comprehensive Assessment',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToChapter(chapter, levelName);
                        },
                        icon: const Icon(Icons.menu_book_rounded, size: 18),
                        label: const Text(
                          'Read Lessons',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _openChapterActivitiesSheet(chapter);
                        },
                        icon: const Icon(
                          Icons.sports_esports_rounded,
                          size: 18,
                          color: Color(0xFF6366F1),
                        ),
                        label: const Text(
                          'Activities',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFF6366F1),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _openChapterActivitiesSheet(MobileChapter chapter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewPadding.bottom;
        return Container(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            bottomInset > 0 ? bottomInset + 20 : 36,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.extension_rounded,
                      color: Color(0xFF6366F1),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${chapter.name} - Activities',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Choose an activity to practice this chapter',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildActivityTile(
                title: 'MCQ Arena Challenge',
                subtitle: '5 speed questions testing chapter grammar & terms',
                icon: Icons.quiz_rounded,
                color: const Color(0xFF6366F1),
                xp: '+100 XP',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          McqGameScreen(title: '${chapter.name} - MCQ'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              _buildActivityTile(
                title: 'Match It: Word & Meaning Pairs',
                subtitle: 'Pair chapter vocabulary with corresponding meanings',
                icon: Icons.extension_rounded,
                color: const Color(0xFF10B981),
                xp: '+100 XP',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MatchGameScreen(title: '${chapter.name} - Match It'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              _buildActivityTile(
                title: 'Fill in the Blanks: Sentence Builder',
                subtitle: 'Place missing grammar chips into chapter sentences',
                icon: Icons.edit_note_rounded,
                color: const Color(0xFF8B5CF6),
                xp: '+100 XP',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FillBlanksGameScreen(
                        title: '${chapter.name} - Fill in Blanks',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String xp,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            xp,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
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
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('📚', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  widget.course.code,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
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

              const Text(
                'Course Curriculum Levels',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
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
              else
                // ================================================================
                // 📋 ONE BY ONE VERTICAL LEVELS & CHAPTERS (No Horizontal Scroll!)
                // ================================================================
                ...List.generate(_levels.length, (levelIndex) {
                  final level = _levels[levelIndex];
                  final levelColor = _getLevelColor(levelIndex);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: levelColor.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: levelColor.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: levelColor,
                                  shape: BoxShape.circle,
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
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  level.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                '${level.chapters.length} ${level.chapters.length == 1 ? 'Chapter' : 'Chapters'}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: levelColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Chapters Under This Level (Vertical One by One)
                        ...level.chapters.map((chapter) {
                          return _buildChapterCard(
                            chapter,
                            levelColor,
                            level.name,
                          );
                        }),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterCard(
    MobileChapter chapter,
    Color color,
    String levelName,
  ) {
    final bool isCompleted = chapter.progress >= 1.0;
    final double progress = chapter.progress;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: progress > 0
              ? color.withValues(alpha: 0.4)
              : const Color(0xFFE2E8F0),
          width: progress > 0 ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: progress > 0 ? 0.08 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openLessonDialog(chapter, color, levelName),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                                    : Icons.lock_outline_rounded),
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
                              fontSize: 15,
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
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${chapter.contentsCount} Lessons • ${chapter.assessmentsCount} Quiz',
                      style: const TextStyle(
                        fontSize: 12,
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
                          '+${chapter.contentsCount * 20} XP',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
