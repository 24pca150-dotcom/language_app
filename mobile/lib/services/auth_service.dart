import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'cached_user';
  static const List<String> _settingsPrefKeys = [
    'daily_reminder_enabled',
    'daily_reminder_time',
    'daily_goal_minutes',
    'reminder_frequency',
    'reminder_sound',
    'reminder_vibration',
  ];

  /// Set by main.dart to show the login screen when the server rejects the token.
  static void Function()? onSessionExpired;

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Clears the expired login and lets the app return to the login screen.
  static Future<void> handleSessionExpired() async {
    await _clearLocalSession();
    onSessionExpired?.call();
  }

  static Future<void> _clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    for (final key in _settingsPrefKeys) {
      await prefs.remove(key);
    }
  }

  /// Keeps the on-device copy of the settings equal to the account's settings.
  static Future<void> _cacheSettings(SharedPreferences prefs, dynamic settings) async {
    if (settings is! Map) return;
    if (settings['reminder_enabled'] is bool) {
      await prefs.setBool('daily_reminder_enabled', settings['reminder_enabled']);
    }
    if (settings['reminder_time'] is String) {
      await prefs.setString('daily_reminder_time', settings['reminder_time']);
    }
    if (settings['daily_goal_minutes'] is int) {
      await prefs.setInt('daily_goal_minutes', settings['daily_goal_minutes']);
    }
    if (settings['reminder_frequency'] is String) {
      await prefs.setString('reminder_frequency', settings['reminder_frequency']);
    }
    if (settings['sound_enabled'] is bool) {
      await prefs.setBool('reminder_sound', settings['sound_enabled']);
    }
    if (settings['vibration_enabled'] is bool) {
      await prefs.setBool('reminder_vibration', settings['vibration_enabled']);
    }
  }

  static Future<bool> saveSettings(Map<String, dynamic> settings) async {
    final token = await getToken();
    final tenantCode = await ApiConfig.getTenantCode();
    final baseUrl = await ApiConfig.getBaseUrl();

    try {
      final res = await http
          .put(
            Uri.parse('$baseUrl/profile/settings'),
            headers: ApiConfig.headers(token: token, tenantCode: tenantCode),
            body: jsonEncode(settings),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 401) {
        await handleSessionExpired();
      }
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Login with Laravel API
  static Future<Map<String, dynamic>> login(String login, String password, {String tenantCode = 'SCH-001'}) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: ApiConfig.headers(tenantCode: tenantCode),
            body: jsonEncode({
              'login': login,
              'password': password,
              'tenant_code': tenantCode,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'] ?? data['token'];
        final userData = data['user'] ?? data['data'];
        final serverTenant = data['tenant_code'] ?? tenantCode;

        final prefs = await SharedPreferences.getInstance();
        if (token != null) {
          await prefs.setString(_tokenKey, token);
        }
        if (userData != null) {
          await prefs.setString(_userKey, jsonEncode(userData));
          await _cacheSettings(prefs, userData['settings']);
        }
        await ApiConfig.setTenantCode(serverTenant);

        return {
          'success': true,
          'token': token,
          'user': userData != null ? UserModel.fromJson(userData) : null,
        };
      } else {
        final err = jsonDecode(response.body);
        String msg = 'Invalid credentials';
        if (err['message'] != null) {
          msg = err['message'];
        } else if (err['errors'] != null && err['errors']['login'] != null) {
          msg = err['errors']['login'][0];
        }
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot reach Laravel API at $baseUrl. Check if php artisan serve is running.',
        'error': e.toString(),
      };
    }
  }

  // Quick Student Login (Authenticates Karthik directly with DB)
  static Future<UserModel> loginDemoUser() async {
    // Try to login as student Karthik with database
    final res = await login('karthik', 'student123', tenantCode: 'SCH-001');
    if (res['success'] == true && res['user'] != null) {
      return res['user'] as UserModel;
    }

    // If cached user exists from a previous successful session
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_userKey);
    if (cached != null) {
      try {
        final parsed = jsonDecode(cached);
        return UserModel.fromJson(parsed);
      } catch (_) {}
    }

    // Default clean baseline with real 0 starting stats
    return UserModel(
      id: 0,
      name: 'Student',
      email: '',
      role: 'student',
      streakDays: 0,
      xp: 0,
      coins: 0,
    );
  }

  static Future<UserModel> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = await getToken();
    final tenantCode = await ApiConfig.getTenantCode();

    // 1. Try to fetch fresh live gamified stats from Laravel backend (/me)
    if (token != null && token != 'demo_token_fallback') {
      try {
        final baseUrl = await ApiConfig.getBaseUrl();
        final res = await http
            .get(
              Uri.parse('$baseUrl/me'),
              headers: ApiConfig.headers(token: token, tenantCode: tenantCode),
            )
            .timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final userData = data['user'] ?? data;
          final user = UserModel.fromJson(userData);
          await prefs.setString(_userKey, jsonEncode(user.toJson()));
          await _cacheSettings(prefs, userData['settings']);
          return user;
        }
        if (res.statusCode == 401) {
          await handleSessionExpired();
        }
      } catch (_) {}
    }

    // 2. Fall back to cached user in SharedPreferences
    final cached = prefs.getString(_userKey);
    if (cached != null) {
      try {
        final parsed = jsonDecode(cached);
        return UserModel.fromJson(parsed);
      } catch (_) {}
    }

    // 3. Fallback baseline (clean zero values, not fake gamified stats)
    return UserModel(
      id: 0,
      name: 'Student',
      email: '',
      role: 'student',
      streakDays: 0,
      xp: 0,
      coins: 0,
    );
  }

  /// Saves to the server first, so the change also shows on web. Throws if it fails.
  static Future<UserModel> updateUserProfile({required String name, required String email}) async {
    final token = await getToken();
    final tenantCode = await ApiConfig.getTenantCode();
    final baseUrl = await ApiConfig.getBaseUrl();

    final res = await http
        .put(
          Uri.parse('$baseUrl/profile'),
          headers: ApiConfig.headers(token: token, tenantCode: tenantCode),
          body: jsonEncode({
            'name': name.trim(),
            if (email.trim().isNotEmpty) 'email': email.trim(),
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (res.statusCode == 401) {
      await handleSessionExpired();
    }
    if (res.statusCode != 200) {
      String message = 'Could not save your profile. Please try again.';
      try {
        message = jsonDecode(res.body)['message'] ?? message;
      } catch (_) {}
      throw Exception(message);
    }

    return getUserProfile();
  }

  static Future<void> logout() async {
    final token = await getToken();
    final tenantCode = await ApiConfig.getTenantCode();
    final baseUrl = await ApiConfig.getBaseUrl();

    if (token != null && token != 'demo_token_fallback') {
      try {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: ApiConfig.headers(token: token, tenantCode: tenantCode),
        );
      } catch (_) {}
    }

    await _clearLocalSession();
  }
}
