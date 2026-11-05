import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class AssessmentOption {
  final int id;
  final String text;
  final bool isCorrect;

  AssessmentOption({
    required this.id,
    required this.text,
    required this.isCorrect,
  });

  factory AssessmentOption.fromJson(Map<String, dynamic> json) {
    final rawCorrect = json['is_correct'];
    final isCorrect = rawCorrect == true || rawCorrect == 1 || rawCorrect == '1' || rawCorrect == 'true';
    return AssessmentOption(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      text: (json['option_text'] ?? json['text'] ?? '').toString(),
      isCorrect: isCorrect,
    );
  }
}

class AssessmentQuestionModel {
  final int id;
  final String questionText;
  final List<AssessmentOption> options;

  AssessmentQuestionModel({
    required this.id,
    required this.questionText,
    required this.options,
  });

  factory AssessmentQuestionModel.fromJson(Map<String, dynamic> json) {
    final opts = (json['options'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AssessmentOption.fromJson)
        .toList();
    return AssessmentQuestionModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      questionText: (json['question_text'] ?? json['question'] ?? '').toString(),
      options: opts,
    );
  }
}

class AssessmentModel {
  final int id;
  final String title;
  final String description;
  final int totalQuestions;
  final int timeLimitMinutes;
  final int passPercentage;
  final double? bestScore;
  final bool isPassed;
  final int totalAttempts;
  final List<AssessmentQuestionModel> questions;

  AssessmentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.totalQuestions,
    this.timeLimitMinutes = 15,
    this.passPercentage = 60,
    this.bestScore,
    this.isPassed = false,
    this.totalAttempts = 0,
    required this.questions,
  });

  factory AssessmentModel.fromJson(Map<String, dynamic> json) {
    final qList = (json['questions'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AssessmentQuestionModel.fromJson)
        .toList();

    int parseTotalQuestions() {
      if (qList.isNotEmpty) return qList.length;
      final tq = json['total_questions'] ?? json['total_marks'];
      if (tq is int) return tq;
      if (tq != null) return int.tryParse(tq.toString().split('.').first) ?? 0;
      return 0;
    }

    int parseTimeLimit() {
      final t = json['time_limit_minutes'] ?? json['duration_minutes'];
      if (t is int) return t;
      if (t != null) return int.tryParse(t.toString().split('.').first) ?? 15;
      return 15;
    }

    int parsePassPercentage() {
      final p = json['pass_percentage'];
      if (p is int) return p;
      if (p is num) return p.toInt();
      if (p != null) return int.tryParse(p.toString().split('.').first) ?? 60;
      return 60;
    }

    double? parseBestScore() {
      final s = json['best_score'] ?? json['latest_attempt']?['score'];
      if (s is num) return s.toDouble();
      if (s != null) return double.tryParse(s.toString());
      return null;
    }

    bool parseIsPassed() {
      if (json['is_passed'] == true || json['is_passed'] == 1 || json['is_passed'] == '1') return true;
      if (json['latest_attempt'] != null) {
        final p = json['latest_attempt']['passed'];
        if (p == true || p == 1 || p == '1') return true;
      }
      return false;
    }

    int parseTotalAttempts() {
      final a = json['total_attempts_count'] ?? json['total_attempts'];
      if (a is int) return a;
      if (a != null) return int.tryParse(a.toString()) ?? 0;
      if (json['latest_attempt'] != null) return 1;
      return 0;
    }

    return AssessmentModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      title: (json['title'] ?? 'Assessment').toString(),
      description: (json['description'] ?? 'Curriculum mastery assessment').toString(),
      totalQuestions: parseTotalQuestions(),
      timeLimitMinutes: parseTimeLimit(),
      passPercentage: parsePassPercentage(),
      bestScore: parseBestScore(),
      isPassed: parseIsPassed(),
      totalAttempts: parseTotalAttempts(),
      questions: qList,
    );
  }
}

class AssessmentService {
  static Future<List<AssessmentModel>> getAssessments() async {
    final token = await AuthService.getToken();
    final tenantCode = await ApiConfig.getTenantCode();
    final baseUrl = await ApiConfig.getBaseUrl();

    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/assessments'),
            headers: ApiConfig.headers(token: token, tenantCode: tenantCode),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 401) {
        await AuthService.handleSessionExpired();
        return [];
      }

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty) {
          final list = data
              .whereType<Map<String, dynamic>>()
              .map(AssessmentModel.fromJson)
              .toList();
          return list;
        }
      }
    } catch (_) {}

    return [];
  }

  static Future<Map<String, dynamic>?> getStudentProgress() async {
    final token = await AuthService.getToken();
    final tenantCode = await ApiConfig.getTenantCode();
    final baseUrl = await ApiConfig.getBaseUrl();

    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/student/dashboard'),
            headers: ApiConfig.headers(token: token, tenantCode: tenantCode),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 401) {
        await AuthService.handleSessionExpired();
        return null;
      }

      if (res.statusCode == 200) {
        final map = jsonDecode(res.body);
        if (map is Map<String, dynamic>) {
          return map;
        }
      }
    } catch (_) {}

    return null;
  }

  static Future<Map<String, dynamic>> submitAssessment({
    required int assessmentId,
    required int correctAnswers,
    required int totalQuestions,
  }) async {
    final token = await AuthService.getToken();
    final tenantCode = await ApiConfig.getTenantCode();
    final baseUrl = await ApiConfig.getBaseUrl();
    final user = await AuthService.getUserProfile();

    final res = await http
        .post(
          Uri.parse('$baseUrl/assessments/$assessmentId/submit'),
          headers: ApiConfig.headers(token: token, tenantCode: tenantCode),
          body: jsonEncode({
            'user_id': user.id,
            'correct_answers': correctAnswers,
            'total_questions': totalQuestions,
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (res.statusCode != 200) {
      throw Exception('Unable to submit assessment (${res.statusCode}).');
    }

    final data = jsonDecode(res.body);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid assessment submission response.');
    }
    return data;
  }
}
