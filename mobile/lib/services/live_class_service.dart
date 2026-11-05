import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';
import 'auth_service.dart';

class LiveClassModel {
  final int id;
  final String title;
  final String description;
  final String meetingLink;
  final String platform;
  final String instructorName;
  final DateTime? startTime;
  final int durationMinutes;
  final String status;
  final List<dynamic> attachments;

  LiveClassModel({
    required this.id,
    required this.title,
    required this.description,
    required this.meetingLink,
    this.platform = 'other',
    this.instructorName = 'Instructor',
    this.startTime,
    this.durationMinutes = 45,
    this.status = 'scheduled',
    this.attachments = const [],
  });

  bool get isLive => status.toLowerCase() == 'live';

  String get platformName {
    switch (platform.toLowerCase()) {
      case 'google_meet':
        return 'Google Meet';
      case 'zoom':
        return 'Zoom Meeting';
      case 'teams':
        return 'MS Teams';
      case 'youtube':
        return 'YouTube Live';
      default:
        return 'Live Room';
    }
  }

  String get formattedTime {
    if (startTime == null) return 'Scheduled soon';
    final now = DateTime.now();
    final local = startTime!.toLocal();
    final isToday = local.year == now.year && local.month == now.month && local.day == now.day;
    final isTomorrow = local.year == now.year && local.month == now.month && local.day == (now.day + 1);

    final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = local.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minuteStr $ampm';

    if (isLive) return 'Broadcasting Live Now';
    if (isToday) return 'Today at $timeStr';
    if (isTomorrow) return 'Tomorrow at $timeStr';
    return '${local.day}/${local.month} at $timeStr';
  }

  factory LiveClassModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedStart;
    if (json['start_time'] != null) {
      try {
        parsedStart = DateTime.parse(json['start_time'].toString());
      } catch (_) {}
    }

    return LiveClassModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      title: (json['title'] ?? 'Live Classroom Session').toString(),
      description: (json['description'] ?? 'Live interactive learning session.').toString(),
      meetingLink: (json['meeting_link'] ?? '').toString(),
      platform: (json['platform'] ?? 'other').toString(),
      instructorName: (json['instructor_name'] ?? 'Faculty Instructor').toString(),
      startTime: parsedStart,
      durationMinutes: int.tryParse('${json['duration_minutes']}') ?? 45,
      status: (json['status'] ?? 'scheduled').toString(),
      attachments: json['attachments'] as List<dynamic>? ?? const [],
    );
  }
}

class LiveClassService {
  static Future<List<LiveClassModel>> getUpcomingLiveClasses() async {
    final token = await AuthService.getToken();
    final tenantCode = await ApiConfig.getTenantCode();
    final baseUrl = await ApiConfig.getBaseUrl();

    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/live-classes/upcoming'),
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
              .map(LiveClassModel.fromJson)
              .toList();
          return list;
        }
      }
    } catch (_) {}

    return [];
  }

  /// Launch external meeting URL (Google Meet / Zoom / Teams) or copy to clipboard
  static Future<bool> joinMeeting(String link) async {
    if (link.isEmpty) return false;
    try {
      final uri = Uri.parse(link.trim());
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    // Fallback: copy link to clipboard so user can open in browser or app
    try {
      await Clipboard.setData(ClipboardData(text: link));
      return true;
    } catch (_) {}

    return false;
  }
}
