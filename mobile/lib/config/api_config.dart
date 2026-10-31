import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _customHostKey = 'custom_api_host';
  static const String _tenantCodeKey = 'tenant_code';
  static String? _workingBaseUrl;

  // Candidate API URLs for physical devices, emulators, and local machines
  static List<String> get candidateUrls {
    return [
      'http://192.168.1.48:8000/api',
      'http://127.0.0.1:8000/api',
      'http://10.0.2.2:8000/api',
    ];
  }

  static Future<String> getBaseUrl() async {
    if (_workingBaseUrl != null) return _workingBaseUrl!;

    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getString(_customHostKey);
    if (custom != null && custom.isNotEmpty) {
      _workingBaseUrl = custom;
      return custom;
    }

    // Probe candidates quickly to find the reachable host
    for (final candidate in candidateUrls) {
      try {
        final res = await http
            .get(Uri.parse('$candidate/courses'))
            .timeout(const Duration(milliseconds: 1500));
        if (res.statusCode == 200 || res.statusCode == 401) {
          _workingBaseUrl = candidate;
          await prefs.setString(_customHostKey, candidate);
          return candidate;
        }
      } catch (_) {}
    }

    // Default fallback
    _workingBaseUrl = 'http://192.168.1.48:8000/api';
    return _workingBaseUrl!;
  }

  static Future<void> setCustomBaseUrl(String url) async {
    _workingBaseUrl = url;
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
