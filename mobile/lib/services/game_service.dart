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

        if (games.isNotEmpty) return games;
      }
    } catch (e) {
      debugPrint('Error fetching activities from API: $e');
    }

    return getMasterGames();
  }

  static List<MobileGameItem> getMasterGames() {
    return [
      MobileGameItem(
        id: 1,
        title: 'Highway Racer: 3-Lane Speedway',
        subtitle: 'Steer car to correct lane across 5 language challenges',
        type: 'car_racer',
        icon: Icons.directions_car_rounded,
        color: const Color(0xFFD97706),
        xp: '+100 XP',
        badge: '5 CHALLENGES',
        questionCount: 5,
      ),
      MobileGameItem(
        id: 2,
        title: 'Word Ninja: Katana Dojo',
        subtitle: 'Slice target parts of speech across 5 action rounds',
        type: 'word_ninja',
        icon: Icons.sports_martial_arts_rounded,
        color: const Color(0xFFE11D48),
        xp: '+100 XP',
        badge: '5 ROUNDS',
        questionCount: 5,
      ),
      MobileGameItem(
        id: 3,
        title: 'Flappy Word: Skyways Flight',
        subtitle: 'Flap wings & steer through 5 word cloud gates',
        type: 'flappy_word',
        icon: Icons.flight_takeoff_rounded,
        color: const Color(0xFF0284C7),
        xp: '+100 XP',
        badge: '5 CLOUD GATES',
        questionCount: 5,
      ),
      MobileGameItem(
        id: 4,
        title: 'Balloon Word Pop: Sky Fiesta',
        subtitle: 'Pop rising target balloons across 5 vocabulary missions',
        type: 'balloon_pop',
        icon: Icons.bubble_chart_rounded,
        color: const Color(0xFF10B981),
        xp: '+80 XP',
        badge: '5 MISSIONS',
        questionCount: 5,
      ),
      MobileGameItem(
        id: 5,
        title: 'MCQ Arena: Rapid Grammar & Vocab',
        subtitle: 'Speed quiz on irregular verbs, antonyms & speech rules',
        type: 'mcq',
        icon: Icons.quiz_rounded,
        color: const Color(0xFF6366F1),
        xp: '+100 XP',
        badge: '5 QUESTIONS',
        questionCount: 5,
      ),
      MobileGameItem(
        id: 6,
        title: 'Match It: Connect Pairs',
        subtitle: 'Connect words with meanings, synonyms & antonyms',
        type: 'match',
        icon: Icons.extension_rounded,
        color: const Color(0xFF0D9488),
        xp: '+100 XP',
        badge: '5 PAIRS',
        questionCount: 5,
      ),
      MobileGameItem(
        id: 7,
        title: 'Flashcard Mastery: Word Deck',
        subtitle: 'Flip through vocabulary decks with definitions & audio',
        type: 'flashcard',
        icon: Icons.style_rounded,
        color: const Color(0xFFF59E0B),
        xp: '+100 XP',
        badge: '5 FLASHCARDS',
        questionCount: 5,
      ),
      MobileGameItem(
        id: 8,
        title: 'Fill in the Blanks: Sentence Builder',
        subtitle: 'Select and place missing grammar words into sentences',
        type: 'fill_blanks',
        icon: Icons.edit_note_rounded,
        color: const Color(0xFF8B5CF6),
        xp: '+100 XP',
        badge: '5 SENTENCES',
        questionCount: 5,
      ),
    ];
  }
}
