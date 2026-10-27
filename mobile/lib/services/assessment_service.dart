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
    return AssessmentOption(
      id: json['id'] ?? 0,
      text: json['option_text'] ?? json['text'] ?? '',
      isCorrect: json['is_correct'] == true || json['is_correct'] == 1,
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
        .map((o) => AssessmentOption.fromJson(o))
        .toList();
    return AssessmentQuestionModel(
      id: json['id'] ?? 0,
      questionText: json['question_text'] ?? json['question'] ?? '',
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
        .map((q) => AssessmentQuestionModel.fromJson(q))
        .toList();

    return AssessmentModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Assessment',
      description: json['description'] ?? 'Curriculum mastery assessment',
      totalQuestions: qList.isNotEmpty
          ? qList.length
          : json['total_questions'] ?? json['total_marks'] ?? 0,
      timeLimitMinutes:
          json['time_limit_minutes'] ?? json['duration_minutes'] ?? 15,
      passPercentage: json['pass_percentage'] ?? 60,
      bestScore: (json['best_score'] as num?)?.toDouble(),
      isPassed: json['is_passed'] == true,
      totalAttempts: json['total_attempts_count'] ?? 0,
      questions: qList,
    );
  }
}

class AssessmentService {
  static Future<List<AssessmentModel>> getAssessments() async {
    final token = await AuthService.getToken();
    final tenantCode = await ApiConfig.getTenantCode();
    final baseUrl = await ApiConfig.getBaseUrl();

    final res = await http
        .get(
          Uri.parse('$baseUrl/assessments'),
          headers: ApiConfig.headers(token: token, tenantCode: tenantCode),
        )
        .timeout(const Duration(seconds: 8));

    if (res.statusCode != 200) {
      throw Exception('Unable to load assessments (${res.statusCode}).');
    }

    final data = jsonDecode(res.body);
    if (data is! List) {
      throw const FormatException('Invalid assessments response.');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(AssessmentModel.fromJson)
        .toList();
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

  static List<AssessmentModel> getFallbackAssessments() {
    return [
      AssessmentModel(
        id: 1,
        title: 'Level 1: Homophones & Listening Mastery Assessment',
        description: 'Test your understanding of identical sounding words and vocabulary definitions.',
        totalQuestions: 5,
        timeLimitMinutes: 10,
        passPercentage: 60,
        bestScore: 80.0,
        isPassed: true,
        questions: [
          AssessmentQuestionModel(
            id: 101,
            questionText: 'Select the correct homophone: "I can ____ the waves crashing onto the shore."',
            options: [
              AssessmentOption(id: 1, text: 'hear', isCorrect: true),
              AssessmentOption(id: 2, text: 'here', isCorrect: false),
              AssessmentOption(id: 3, text: 'hare', isCorrect: false),
              AssessmentOption(id: 4, text: 'hair', isCorrect: false),
            ],
          ),
          AssessmentQuestionModel(
            id: 102,
            questionText:
                'Which word has the exact same pronunciation as "Sea"?',
            options: [
              AssessmentOption(id: 5, text: 'See', isCorrect: true),
              AssessmentOption(id: 6, text: 'Saw', isCorrect: false),
              AssessmentOption(id: 7, text: 'Say', isCorrect: false),
              AssessmentOption(id: 8, text: 'Sew', isCorrect: false),
            ],
          ),
          AssessmentQuestionModel(
            id: 103,
            questionText: 'Choose the correct word: "The bright ____ rose early in the morning sky."',
            options: [
              AssessmentOption(id: 9, text: 'son', isCorrect: false),
              AssessmentOption(id: 10, text: 'sun', isCorrect: true),
              AssessmentOption(id: 11, text: 'soon', isCorrect: false),
              AssessmentOption(id: 12, text: 'scene', isCorrect: false),
            ],
          ),
          AssessmentQuestionModel(
            id: 104,
            questionText: 'Which pair consists of valid homophones?',
            options: [
              AssessmentOption(id: 13, text: 'Book - Look', isCorrect: false),
              AssessmentOption(id: 14, text: 'Right - Write', isCorrect: true),
              AssessmentOption(id: 15, text: 'Cat - Bat', isCorrect: false),
              AssessmentOption(id: 16, text: 'Fast - Slow', isCorrect: false),
            ],
          ),
          AssessmentQuestionModel(
            id: 105,
            questionText: 'What is the correct sound produced by an Elephant?',
            options: [
              AssessmentOption(id: 17, text: 'Roar', isCorrect: false),
              AssessmentOption(id: 18, text: 'Trumpet', isCorrect: true),
              AssessmentOption(id: 19, text: 'Chirp', isCorrect: false),
              AssessmentOption(id: 20, text: 'Bleat', isCorrect: false),
            ],
          ),
        ],
      ),
      AssessmentModel(
        id: 2,
        title: 'Level 2: Animal Sounds & Grammar Identification',
        description:
            'Comprehensive quiz on nature vocabulary, verb tenses, and sounds.',
        totalQuestions: 4,
        timeLimitMinutes: 10,
        passPercentage: 60,
        questions: [
          AssessmentQuestionModel(
            id: 201,
            questionText: 'Which animal produces a "Neigh" or "Whinny"?',
            options: [
              AssessmentOption(id: 21, text: 'Dog', isCorrect: false),
              AssessmentOption(id: 22, text: 'Horse', isCorrect: true),
              AssessmentOption(id: 23, text: 'Lion', isCorrect: false),
              AssessmentOption(id: 24, text: 'Sheep', isCorrect: false),
            ],
          ),
          AssessmentQuestionModel(
            id: 202,
            questionText: 'What is the past tense of the verb "Write"?',
            options: [
              AssessmentOption(id: 25, text: 'Writing', isCorrect: false),
              AssessmentOption(id: 26, text: 'Wrote', isCorrect: true),
              AssessmentOption(id: 27, text: 'Written', isCorrect: false),
              AssessmentOption(id: 28, text: 'Wroten', isCorrect: false),
            ],
          ),
        ],
      ),
    ];
  }
}
