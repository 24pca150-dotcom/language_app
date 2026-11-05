import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class MobileGameItem {
  final int id;
  final String title;
  final String subtitle;
  final String type;
  final IconData icon;
  final Color color;
  final String xp;
  final String badge;
  final int questionCount;
  final Map<String, dynamic>? dataJson;

  MobileGameItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.icon,
    required this.color,
    required this.xp,
    required this.badge,
    this.questionCount = 5,
    this.dataJson,
  });
}

class GameService {
  /// Saves a finished game on the server so its points show on web and mobile.
  static Future<void> recordActivity(
    String activityType, {
    int score = 100,
    int total = 100,
    int count = 1,
  }) async {
    final token = await AuthService.getToken();
    final tenantCode = await ApiConfig.getTenantCode();
    final baseUrl = await ApiConfig.getBaseUrl();

    try {
      await http
          .post(
            Uri.parse('$baseUrl/dashboard/record-activity'),
            headers: ApiConfig.headers(token: token, tenantCode: tenantCode),
            body: jsonEncode({
              'activity_type': activityType,
              'score': score,
              'total': total,
              'count': count.clamp(1, 100),
            }),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  /// Fetches real-time activities created by Admin/Superadmin from Laravel API.
  /// If admin adds an activity in Web, it immediately shows up here!
  static Future<List<MobileGameItem>> getDatabaseGames() async {
    try {
      final token = await AuthService.getToken();
      final tenantCode = await ApiConfig.getTenantCode();
      final baseUrl = await ApiConfig.getBaseUrl();

      final res = await http
          .get(
            Uri.parse('$baseUrl/activities'),
            headers: ApiConfig.headers(token: token, tenantCode: tenantCode),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List<dynamic> list = decoded is List
            ? decoded
            : (decoded is Map && decoded['data'] is List
                ? decoded['data'] as List
                : []);

        final List<MobileGameItem> games = [];
        for (var raw in list) {
          if (raw is! Map) continue;
          final item = Map<String, dynamic>.from(raw);

          final type = (item['type'] ?? 'car_racer').toString().toLowerCase();
          final title = (item['title'] ?? 'Activity').toString();

          Map<String, dynamic>? dataJson;
          if (item['data_json'] is Map) {
            dataJson = Map<String, dynamic>.from(item['data_json'] as Map);
          } else if (item['data_json'] is String && (item['data_json'] as String).isNotEmpty) {
            try {
              final d = jsonDecode(item['data_json'] as String);
              if (d is Map) dataJson = Map<String, dynamic>.from(d);
            } catch (_) {}
          }

          IconData icon = Icons.extension_rounded;
          Color color = const Color(0xFF6366F1);
          String subtitle = 'Interactive Exercise';
          int count = 5;

          if (type.contains('racer') || type.contains('car')) {
            icon = Icons.directions_car_rounded;
            color = const Color(0xFF0284C7);
            subtitle = 'Steer car to correct lane across word challenges';
            count = (dataJson?['rounds'] as List?)?.length ?? 5;
          } else if (type.contains('ninja')) {
            icon = Icons.sports_martial_arts_rounded;
            color = const Color(0xFFE11D48);
            subtitle = 'Slice flying word target cards with katana';
            count = (dataJson?['words'] as List?)?.length ?? 5;
          } else if (type.contains('flappy')) {
            icon = Icons.flight_takeoff_rounded;
            color = const Color(0xFF0D9488);
            subtitle = 'Fly through correct word cloud gates';
            count = (dataJson?['gates'] as List?)?.length ?? 5;
          } else if (type.contains('balloon')) {
            icon = Icons.bubble_chart_rounded;
            color = const Color(0xFFD946EF);
            subtitle = 'Pop rising target speech balloons in time';
            count = (dataJson?['words'] as List?)?.length ?? 5;
          } else if (type.contains('space')) {
            icon = Icons.rocket_launch_rounded;
            color = const Color(0xFFF97316);
            subtitle = 'Blast alien ships carrying incorrect spellings';
            count = 5;
          } else if (type.contains('mcq')) {
            icon = Icons.quiz_rounded;
            color = const Color(0xFF6366F1);
            subtitle = 'Quick speed quiz & instant grammar answers';
            count = (dataJson?['questions'] as List?)?.length ?? (dataJson?['options'] as List?)?.length ?? 5;
          } else if (type.contains('match')) {
            icon = Icons.extension_rounded;
            color = const Color(0xFF10B981);
            subtitle = 'Connect words with meanings, synonyms & antonyms';
            count = (dataJson?['pairs'] as List?)?.length ?? 5;
          } else if (type.contains('flashcard')) {
            icon = Icons.style_rounded;
            color = const Color(0xFFD97706);
            subtitle = 'Flip through vocabulary decks with definitions';
            count = (dataJson?['cards'] as List?)?.length ?? 5;
          } else if (type.contains('fill_blanks') || type.contains('blank')) {
            icon = Icons.edit_note_rounded;
            color = const Color(0xFF8B5CF6);
            subtitle = 'Select and place missing words into sentences';
            count = (dataJson?['blanks'] as List?)?.length ?? 5;
          } else if (type.contains('writing')) {
            icon = Icons.border_color_rounded;
            color = const Color(0xFFEA580C);
            subtitle = 'Practice typing and completing sentences';
            count = 5;
          } else if (type.contains('arrange') || type.contains('unscramble')) {
            icon = Icons.sort_by_alpha_rounded;
            color = const Color(0xFFEC4899);
            subtitle = 'Unscramble words into correct grammar sentences';
            count = 5;
          } else if (type.contains('crossword')) {
            icon = Icons.grid_on_rounded;
            color = const Color(0xFF14B8A6);
            subtitle = 'Solve vocabulary crossword clues and grid';
            count = 5;
          } else {
            icon = Icons.sports_esports_rounded;
            color = const Color(0xFF475569);
            subtitle = 'Interactive language game';
          }

          games.add(
            MobileGameItem(
              id: item['id'] is int ? item['id'] as int : int.tryParse('${item['id']}') ?? 0,
              title: title,
              subtitle: subtitle,
              type: type,
              icon: icon,
              color: color,
              xp: '+100 XP',
              badge: type.toUpperCase().replaceAll('_', ' '),
              questionCount: count,
              dataJson: dataJson,
            ),
          );
        }

        return games;
      }
    } catch (e) {
      debugPrint('Error fetching activities from API: $e');
    }

    return [];
  }
}
