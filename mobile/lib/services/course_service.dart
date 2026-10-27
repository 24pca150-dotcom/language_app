import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

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
    final chaptersList = (json['chapters'] as List<dynamic>? ?? [])
        .map((c) => MobileChapter.fromJson(c))
        .toList();

    return MobileLevel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      levelNumber: json['level_number'] ?? json['sort_order'] ?? 1,
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

  MobileChapter({
    required this.id,
    required this.name,
    this.description,
    this.contentsCount = 0,
    this.assessmentsCount = 0,
    this.progress = 0.0,
  });

  factory MobileChapter.fromJson(Map<String, dynamic> json) {
    final contents = json['contents'] as List<dynamic>? ?? [];
    final assessments = json['assessments'] as List<dynamic>? ?? [];
    return MobileChapter(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      contentsCount: contents.length,
      assessmentsCount: assessments.length,
      progress: 0.0,
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
    return MobileCourseItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      levelsCount: json['levels_count'] ?? json['no_of_levels'] ?? 0,
      chaptersCount: json['chapters_count'] ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      colorValue: 0xFF6366F1,
      icon: '📚',
    );
  }
}

class CourseService {
  static Future<List<MobileCourseItem>> getCourses() async {
    final token = await AuthService.getToken();
    final tenantCode = await ApiConfig.getTenantCode();
    final baseUrl = await ApiConfig.getBaseUrl();

    final res = await http
        .get(
          Uri.parse('$baseUrl/courses'),
          headers: ApiConfig.headers(token: token, tenantCode: tenantCode),
        )
        .timeout(const Duration(seconds: 8));

    if (res.statusCode != 200) {
      throw Exception('Unable to load courses (${res.statusCode}).');
    }

    final data = jsonDecode(res.body);
    final list = data is List
        ? data
        : data is Map<String, dynamic> && data['data'] is List
        ? data['data'] as List<dynamic>
        : throw const FormatException('Invalid courses response.');

    return list
        .whereType<Map<String, dynamic>>()
        .where(
          (course) => course['is_active'] == true || course['is_active'] == 1,
        )
        .map(MobileCourseItem.fromJson)
        .toList();
  }

  static Future<List<MobileLevel>> getCourseStructure({
    required int courseId,
  }) async {
    final token = await AuthService.getToken();
    final tenantCode = await ApiConfig.getTenantCode();
    final baseUrl = await ApiConfig.getBaseUrl();

    final res = await http
        .get(
          Uri.parse('$baseUrl/courses/$courseId/player-structure'),
          headers: ApiConfig.headers(token: token, tenantCode: tenantCode),
        )
        .timeout(const Duration(seconds: 8));

    if (res.statusCode != 200) {
      throw Exception('Unable to load course content (${res.statusCode}).');
    }

    final data = jsonDecode(res.body);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid course structure response.');
    }

    final levelsData = data['levels'] as List<dynamic>? ?? [];
    return levelsData
        .whereType<Map<String, dynamic>>()
        .map(MobileLevel.fromJson)
        .toList();
  }
}
