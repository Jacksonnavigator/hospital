import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class SessionService {
  SessionService._();

  static final SessionService instance = SessionService._();

  static const _tokenKey = 'qmedco.token';
  static const _roleKey = 'qmedco.role';
  static const _nameKey = 'qmedco.name';
  static const _emailKey = 'qmedco.email';

  Map<String, dynamic>? user;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) return;

    ApiClient.instance.setToken(token);
    try {
      final current = await ApiClient.instance.get('/api/me');
      user = current['user'] as Map<String, dynamic>;
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_roleKey, user!['role']?.toString() ?? 'patient');
      await prefs.setString(_nameKey, user!['fullName']?.toString() ?? '');
      await prefs.setString(_emailKey, user!['email']?.toString() ?? '');
    } catch (_) {
      await logout();
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await ApiClient.instance.post('/api/auth/login', {
      'email': email,
      'password': password,
    });
    await _save(data);
    return user!;
  }

  Future<Map<String, dynamic>> register(
    String fullName,
    String email,
    String password,
  ) async {
    final data = await ApiClient.instance.post('/api/auth/register', {
      'fullName': fullName,
      'email': email,
      'password': password,
    });
    await _save(data);
    return user!;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    ApiClient.instance.setToken(null);
    user = null;
  }

  Future<void> _save(Map<String, dynamic> auth) async {
    final prefs = await SharedPreferences.getInstance();
    final token = auth['token'] as String;
    user = auth['user'] as Map<String, dynamic>;
    ApiClient.instance.setToken(token);
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_roleKey, user!['role']?.toString() ?? 'patient');
    await prefs.setString(_nameKey, user!['fullName']?.toString() ?? '');
    await prefs.setString(_emailKey, user!['email']?.toString() ?? '');
  }
}
