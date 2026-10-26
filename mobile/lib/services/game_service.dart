import 'package:flutter/material.dart';

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
  static Future<List<MobileGameItem>> getDatabaseGames() async {
    // Returns 1 master game card per game mode, each containing 5 questions/challenges inside
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
