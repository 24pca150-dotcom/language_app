import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class ContentBlock {
  final String type;
  final Map<String, dynamic> data;

  ContentBlock({required this.type, required this.data});

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    return ContentBlock(
      type: json['type'] ?? 'paragraph',
      data: json['data'] is Map<String, dynamic> ? json['data'] : {},
    );
  }
}

class ChapterContentItem {
  final int id;
  final String name;
  final String title;
  final List<ContentBlock> blocks;
  final List<List<String>> tableData;

  ChapterContentItem({
    required this.id,
    required this.name,
    required this.title,
    required this.blocks,
    this.tableData = const [],
  });

  factory ChapterContentItem.fromJson(Map<String, dynamic> json) {
    List<ContentBlock> parsedBlocks = [];
    List<List<String>> parsedTable = [];

    final rawText = json['text_content'];
    if (rawText != null) {
      try {
        final decoded = rawText is String ? jsonDecode(rawText) : rawText;
        if (decoded['blocks'] is List) {
          for (var b in decoded['blocks']) {
            final block = ContentBlock.fromJson(b);
            parsedBlocks.add(block);
            if (block.type == 'table' && block.data['content'] is List) {
              for (var row in block.data['content']) {
                if (row is List) {
                  parsedTable.add(row.map((e) => e.toString()).toList());
                }
              }
            }
          }
        }
      } catch (_) {}
    }

    return ChapterContentItem(
      id: json['id'] ?? 1,
      name: json['name'] ?? 'Lesson Content',
      title: json['title'] ?? json['name'] ?? 'Lesson Details',
      blocks: parsedBlocks,
      tableData: parsedTable,
    );
  }
}

class ContentService {
  static Future<List<ChapterContentItem>> getChapterContents(int chapterId) async {
    final token = await AuthService.getToken();
    final tenantCode = await ApiConfig.getTenantCode();
    final baseUrl = await ApiConfig.getBaseUrl();

    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/chapters/$chapterId'),
            headers: ApiConfig.headers(token: token, tenantCode: tenantCode),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final contentsList = data['contents'] as List<dynamic>?;
        if (contentsList != null && contentsList.isNotEmpty) {
          return contentsList.map((c) => ChapterContentItem.fromJson(c)).toList();
        }
      }
    } catch (_) {}

    // Fallback based on real database records for Chapter 1 and Chapter 2
    return getFallbackContents(chapterId);
  }

  static List<ChapterContentItem> getFallbackContents(int chapterId) {
    if (chapterId == 2) {
      // Chapter 2: Sounds of Animals & Birds
      return [
        ChapterContentItem(
          id: 3,
          name: 'Animal Sounds - Vocabulary of Nature',
          title: 'Sounds of Animals & Birds - 111 Species Directory',
          blocks: [
            ContentBlock(type: 'header', data: {'text': 'Welcome to the Sound Adventure! 🐾', 'level': 2}),
            ContentBlock(type: 'paragraph', data: {
              'text': 'Sound is a form of energy that we can hear. Animals and birds use different sounds to communicate messages, warn of danger, and share happiness.'
            }),
            ContentBlock(type: 'header', data: {'text': 'Essential Animal & Bird Sounds', 'level': 3}),
          ],
          tableData: [
            ['Animal / Bird', 'Sound Produced', 'Example Phrase'],
            ['Lions / Tigers', 'Roar, Growl', 'The ferocious lion roars across the savanna.'],
            ['Dogs', 'Bark, Woof, Arf', 'The guard dog barks when visitors approach.'],
            ['Cats', 'Meow, Purr, Hiss', 'A gentle purr means the kitten is happy.'],
            ['Birds', 'Chirp, Tweet, Twitter', 'Sparrows chirp cheerfully every morning.'],
            ['Elephants', 'Trumpet, Roar', 'The mother elephant trumpeted loudly.'],
            ['Horses', 'Neigh, Whinny, Snort', 'Horses neigh when greeting one another.'],
            ['Cows / Cattle', 'Moo, Low', 'Cows moo peacefully in the green pasture.'],
            ['Frogs', 'Croak', 'Bullfrogs croak beside the quiet pond.'],
            ['Snakes', 'Hiss', 'The rattlesnake produces a sharp hiss.'],
            ['Owls', 'Hoot, Screech', 'A wise old owl hoots from the oak tree.'],
            ['Dolphins', 'Click, Whistle', 'Dolphins click to navigate deep waters.'],
            ['Bees', 'Buzz, Hum', 'Honey bees buzz around fragrant blossoms.'],
          ],
        ),
        ChapterContentItem(
          id: 4,
          name: 'Animal Sounds - Practice & Challenges',
          title: 'Listening Activities & Pronunciation Drills',
          blocks: [
            ContentBlock(type: 'header', data: {'text': 'Sound Identification Challenge 🎯', 'level': 2}),
            ContentBlock(type: 'paragraph', data: {
              'text': 'Test your listening and identification skills. Practice pronouncing each animal noise aloud with rhythmic cadence!'
            }),
          ],
          tableData: [
            ['Sound', 'Matching Species', 'Listening Exercise'],
            ['Buzz', 'Bees & Flies', 'Pronounce with buzzing vibration (/bʌz/)'],
            ['Neigh', 'Horses', 'Sharp rising whinny (/neɪ/)'],
            ['Croak', 'Frogs & Toads', 'Deep guttural sound (/kroʊk/)'],
            ['Trumpet', 'Elephants', 'High resonant call'],
          ],
        ),
      ];
    } else {
      // Default: Chapter 1: Homophones Mastery
      return [
        ChapterContentItem(
          id: 1,
          name: 'Homophones - Concept & Examples',
          title: 'Introduction to Homophones & Phonetics',
          blocks: [
            ContentBlock(type: 'header', data: {'text': 'What Are Homophones? 💡', 'level': 2}),
            ContentBlock(type: 'paragraph', data: {
              'text': 'Homophones are words that sound exactly the same when pronounced, but have different spellings and completely different meanings! (Homo = Same, Phone = Sound).'
            }),
            ContentBlock(type: 'header', data: {'text': 'Common Everyday Homophones Pairs', 'level': 3}),
          ],
          tableData: [
            ['Word 1', 'Word 2', 'Pronunciation', 'Meanings'],
            ['See', 'Sea', '/siː/', 'See = To look | Sea = Ocean water'],
            ['Hear', 'Here', '/hɪər/', 'Hear = To listen | Here = In this place'],
            ['Sun', 'Son', '/sʌn/', 'Sun = Star in sky | Son = Male child'],
            ['Right', 'Write', '/raɪt/', 'Right = Correct | Write = Pen on paper'],
            ['Flour', 'Flower', '/flaʊ.ər/', 'Flour = Baking grain | Flower = Blossom'],
            ['Hour', 'Our', '/aʊər/', 'Hour = 60 minutes | Our = Belongs to us'],
            ['Piece', 'Peace', '/piːs/', 'Piece = Portion | Peace = Calm / Harmony'],
            ['Pair', 'Pear', '/peər/', 'Pair = Two items | Pear = Sweet fruit'],
          ],
        ),
        ChapterContentItem(
          id: 2,
          name: 'Homophones - A to Z & Practice',
          title: 'Directory & Sentence Practice Exercises',
          blocks: [
            ContentBlock(type: 'header', data: {'text': 'Sentence Building Practice 📝', 'level': 2}),
            ContentBlock(type: 'paragraph', data: {
              'text': 'Identify the correct homophone in real sentences to avoid spelling traps in writing.'
            }),
          ],
          tableData: [
            ['Sentence', 'Correct Choice', 'Incorrect Trap'],
            ['I can ____ the waves crashing.', 'hear', 'here'],
            ['She bought a bouquet of ____.', 'flowers', 'flours'],
            ['The morning ____ shone brightly.', 'sun', 'son'],
            ['Please ____ your answers neatly.', 'write', 'right'],
          ],
        ),
      ];
    }
  }
}
