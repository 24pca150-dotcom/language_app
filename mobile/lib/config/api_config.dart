import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _customHostKey = 'custom_api_host';
  static const String _tenantCodeKey = 'tenant_code';
  
  // Default base URL depending on platform
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    try {
      if (Platform.isAndroid) {
        // 10.0.2.2 maps to the host machine localhost in Android Emulator
        return 'http://10.0.2.2:8000/api';
      } else if (Platform.isIOS) {
        return 'http://127.0.0.1:8000/api';
      }
    } catch (_) {}
    return 'http://127.0.0.1:8000/api';
  }

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customHostKey) ?? defaultBaseUrl;
  }

  static Future<void> setCustomBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customHostKey, url);
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
