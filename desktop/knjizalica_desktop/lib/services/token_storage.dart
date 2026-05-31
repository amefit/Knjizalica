import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _tokenKey = 'auth_token';
  static const _expiresKey = 'auth_expires_at';
  static const _usernameKey = 'auth_username';

  Future<void> saveToken(String token, DateTime expiresAt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_expiresKey, expiresAt.toIso8601String());
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final expiresRaw = prefs.getString(_expiresKey);
    if (token == null || expiresRaw == null) return null;

    final expiresAt = DateTime.tryParse(expiresRaw);
    if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
      await clear();
      return null;
    }
    return token;
  }

  Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_expiresKey);
    await prefs.remove(_usernameKey);
  }
}
