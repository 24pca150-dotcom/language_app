import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'cached_user';

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty || token == 'demo_token_fallback') {
      try {
        final res = await login('karthik', 'student123', tenantCode: 'SCH-001');
        if (res['success'] == true && res['token'] != null) {
          token = res['token'] as String;
        }
      } catch (_) {}
    }
    return token;
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

    // Fallback if network issue
    final fallbackUser = UserModel(
      id: 12,
      name: 'Karthik',
      email: 'karthik@ariga.school',
      role: 'student',
      streakDays: 1,
      xp: 1475,
      coins: 120,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, 'demo_token_fallback');
    await prefs.setString(_userKey, jsonEncode(fallbackUser.toJson()));
    return fallbackUser;
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
          final user = UserModel.fromJson(data['user'] ?? data);
          await prefs.setString(_userKey, jsonEncode(user.toJson()));
          return user;
        }
      } catch (_) {}
    }

    // 2. Fall back to cached user in SharedPreferences
    final cached = prefs.getString(_userKey);
    if (cached != null) {
      try {
        final parsed = jsonDecode(cached);
        // Ignore stale demo fallback user with fake values (id: 10, xp: 450, streak_days: 7)
        if (parsed['id'] != 10 && parsed['xp'] != 450 && parsed['streak_days'] != 7) {
          return UserModel.fromJson(parsed);
        }
      } catch (_) {}
    }

    // 3. Fallback baseline
    return UserModel(
      id: 12,
      name: 'Karthik',
      email: 'karthik@ariga.school',
      role: 'student',
      streakDays: 1,
      xp: 1475,
      coins: 120,
    );
  }

  static Future<UserModel> updateUserProfile({required String name, required String email}) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = await getUserProfile();

    final updated = UserModel(
      id: currentUser.id,
      name: name.trim().isNotEmpty ? name.trim() : currentUser.name,
      email: email.trim().isNotEmpty ? email.trim() : currentUser.email,
      role: currentUser.role,
      streakDays: currentUser.streakDays,
      xp: currentUser.xp,
      coins: currentUser.coins,
      avatar: currentUser.avatar,
    );

    await prefs.setString(_userKey, jsonEncode(updated.toJson()));
    return updated;
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
