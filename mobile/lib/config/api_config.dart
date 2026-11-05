import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _tenantCodeKey = 'tenant_code';
  static const String _localUrl = 'http://127.0.0.1:8000/api';
  static const String _liveUrl = 'https://learn-api.macvelsoftware.com/api';

  // `flutter run` in a browser uses the local backend; mobile uses the live server.
  static Future<String> getBaseUrl() async {
    return kIsWeb && kDebugMode ? _localUrl : _liveUrl;
  }

  static Future<String?> getTenantCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tenantCodeKey) ?? 'SCH-001';
  }

  static Future<void> setTenantCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tenantCodeKey, code);
  }

  // Common Headers with Bearer token & X-Tenant-Code
  static Map<String, String> headers({String? token, String? tenantCode}) {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Tenant-Code': tenantCode ?? 'SCH-001',
    };
    if (token != null && token.isNotEmpty) {
      map['Authorization'] = 'Bearer $token';
    }
    return map;
  }
}
