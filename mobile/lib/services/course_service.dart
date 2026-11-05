import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class MobileContentInfo {
  final int id;
  final String name;
  final String title;

  MobileContentInfo({
    required this.id,
    required this.name,
    required this.title,
  });

  factory MobileContentInfo.fromJson(Map<String, dynamic> json) {
    return MobileContentInfo(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
    );
  }
}

class MobileActivityInfo {
  final int id;
  final String title;
  final String type;
  final String subtitle;
  final String xp;

  MobileActivityInfo({
    required this.id,
    required this.title,
    required this.type,
    this.subtitle = 'Interactive practice challenge',
    this.xp = '+100 XP',
  });
}

class MobileLevel {
  final int id;
  final String name;
  final int levelNumber;
  final List<MobileChapter> chapters;

  MobileLevel({
    required this.id,
    required this.name,
    required this.levelNumber,
    required this.chapters,
  });

  factory MobileLevel.fromJson(Map<String, dynamic> json) {
    final rawChapters = json['chapters'] as List<dynamic>? ?? [];
    final chaptersList = <MobileChapter>[];
    for (var c in rawChapters) {
      if (c is Map) {
        chaptersList.add(MobileChapter.fromJson(Map<String, dynamic>.from(c)));
      }
    }

    final sortVal = json['sort_order'] ?? json['level_number'];
    int parsedSort = 1;
    if (sortVal is int) {
      parsedSort = sortVal;
    } else if (sortVal != null) {
      parsedSort = int.tryParse(sortVal.toString()) ?? 1;
    }

    return MobileLevel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      levelNumber: parsedSort,
      chapters: chaptersList,
    );
  }
}

class MobileChapter {
  final int id;
  final String name;
  final String? description;
  final int contentsCount;
  final int assessmentsCount;
  final double progress;
  final List<MobileContentInfo> contents;
  final List<MobileActivityInfo> activities;

  MobileChapter({
    required this.id,
    required this.name,
    this.description,
    this.contentsCount = 0,
    this.assessmentsCount = 0,
    this.progress = 0.0,
    this.contents = const [],
    this.activities = const [],
  });

  factory MobileChapter.fromJson(Map<String, dynamic> json) {
    final rawContents = json['contents'] as List<dynamic>? ?? [];
    final assessments = json['assessments'] as List<dynamic>? ?? [];
    final chId = json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0;

    final isDone = json['is_completed'] == true || json['is_completed'] == 1 || json['status'] == 'completed';
    final rawProgress = json['progress'];
    double prog = 0.0;
    if (rawProgress is num) {
      prog = rawProgress > 1 ? rawProgress.toDouble() / 100.0 : rawProgress.toDouble();
    } else if (isDone) {
      prog = 1.0;
    }

    final parsedContents = <MobileContentInfo>[];
    for (var c in rawContents) {
      if (c is Map) {
        parsedContents.add(MobileContentInfo.fromJson(Map<String, dynamic>.from(c)));
      }
    }

    final parsedActivities = <MobileActivityInfo>[];
    for (var a in assessments) {
      if (a is Map) {
        final aMap = Map<String, dynamic>.from(a);
        final actId = aMap['id'] is int ? aMap['id'] as int : int.tryParse('${aMap['id']}') ?? 0;
        final actTitle = (aMap['title'] ?? 'Assessment').toString();
        final actType = (aMap['activity_type'] ?? 'mcq').toString();
        final actSubtitle = (aMap['description'] ?? 'Interactive practice challenge').toString();
        final marks = aMap['total_marks'] ?? 100;
        parsedActivities.add(
          MobileActivityInfo(
            id: actId,
            title: actTitle,
            type: actType,
            subtitle: actSubtitle,
            xp: '+$marks XP',
          ),
        );
      }
    }

    return MobileChapter(
      id: chId,
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      contentsCount: parsedContents.length,
      assessmentsCount: parsedActivities.length,
      progress: prog,
      contents: parsedContents,
      activities: parsedActivities,
    );
  }
}

class MobileCourseItem {
  final int id;
  final String name;
  final String code;
  final String description;
  final int levelsCount;
  final int chaptersCount;
  final double progress;
  final int colorValue;
  final String icon;

  MobileCourseItem({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    this.levelsCount = 0,
    this.chaptersCount = 0,
    this.progress = 0.0,
    this.colorValue = 0xFF6366F1,
    this.icon = '📚',
  });

  factory MobileCourseItem.fromJson(Map<String, dynamic> json) {
    final rawProgress = json['progress'] ?? json['percentage'];
    double prog = 0.0;
    if (rawProgress is num) {
      prog = rawProgress > 1 ? rawProgress.toDouble() / 100.0 : rawProgress.toDouble();
    }

    return MobileCourseItem(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      levelsCount: json['levels_count'] ?? json['no_of_levels'] ?? 0,
      chaptersCount: json['chapters_count'] ?? json['total_chapters'] ?? 0,
      progress: prog,
      colorValue: 0xFF6366F1,
      icon: '📚',
    );
  }
}

class CourseService {
  static Future<bool> completeChapter(int chapterId) async {
    final token = await AuthService.getToken();
    final tenantCode = await ApiConfig.getTenantCode();
    final baseUrl = await ApiConfig.getBaseUrl();

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/chapters/$chapterId/complete'),
        headers: ApiConfig.headers(token: token, tenantCode: tenantCode),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> completeContent(int chapterId, int contentId) async {
    final token = await AuthService.getToken();
    final tenantCode = await ApiConfig.getTenantCode();
    final baseUrl = await ApiConfig.getBaseUrl();

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/chapters/$chapterId/contents/$contentId/complete'),
        headers: ApiConfig.headers(token: token, tenantCode: tenantCode),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<List<MobileCourseItem>> getCourses() async {
    final token = await AuthService.getToken();
    final tenantCode = await ApiConfig.getTenantCode();
    final baseUrl = await ApiConfig.getBaseUrl();

    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/courses'),
            headers: ApiConfig.headers(token: token, tenantCode: tenantCode),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 401) {
        await AuthService.handleSessionExpired();
        return [];
      }

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data is List
            ? data
            : data is Map<String, dynamic> && data['data'] is List
            ? data['data'] as List<dynamic>
            : [];

        final courses = list
            .whereType<Map<String, dynamic>>()
            .where(
              (course) => course['is_active'] == true || course['is_active'] == 1 || course['is_active'] == '1' || course['is_active'] == null,
            )
            .map(MobileCourseItem.fromJson)
            .toList();

        return courses;
      }
    } catch (e) {
      // API error handled gracefully
    }

    return [];
  }

  static Future<List<MobileLevel>> getCourseStructure({
    required int courseId,
  }) async {
    final token = await AuthService.getToken();
    final tenantCode = await ApiConfig.getTenantCode();
    final baseUrl = await ApiConfig.getBaseUrl();

    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/courses/$courseId/player-structure'),
            headers: ApiConfig.headers(token: token, tenantCode: tenantCode),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 401) {
        await AuthService.handleSessionExpired();
        return [];
      }

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map) {
          final levelsData = (data['levels'] as List<dynamic>?) ?? [];
          final levels = <MobileLevel>[];
          for (var item in levelsData) {
            if (item is Map) {
              final lvl = MobileLevel.fromJson(Map<String, dynamic>.from(item));
              // Filter out empty levels (0 chapters)
              if (lvl.chapters.isNotEmpty) {
                levels.add(lvl);
              }
            }
          }
          return levels;
        }
      }
    } catch (_) {}

    return [];
  }
}
