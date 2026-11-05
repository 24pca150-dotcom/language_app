import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class ContentBlock {
  final String type;
  final Map<String, dynamic> data;

  ContentBlock({required this.type, required this.data});

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> blockData = {};
    if (json['data'] is Map) {
      blockData = Map<String, dynamic>.from(json['data'] as Map);
    }
    return ContentBlock(
      type: json['type'] ?? 'paragraph',
      data: blockData,
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
        if (decoded is Map && decoded['blocks'] is List) {
          for (var b in decoded['blocks']) {
            if (b is Map) {
              final block = ContentBlock.fromJson(Map<String, dynamic>.from(b));
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
        }
      } catch (_) {}
    }

    return ChapterContentItem(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      blocks: parsedBlocks,
      tableData: parsedTable,
    );
  }
}

class ContentService {
  static Future<List<ChapterContentItem>> getChapterContents(
    int chapterId,
  ) async {
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
        if (data is Map) {
          final contentsList = (data['contents'] as List<dynamic>?) ?? [];
          final items = <ChapterContentItem>[];
          for (var c in contentsList) {
            if (c is Map) {
              final map = Map<String, dynamic>.from(c);
              if (map['is_active'] != false && map['is_active'] != 0) {
                items.add(ChapterContentItem.fromJson(map));
              }
            }
          }
          return items;
        }
      }
    } catch (_) {}

    return [];
  }
}
