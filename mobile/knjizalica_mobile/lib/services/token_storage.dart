import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _tokenKey = 'auth_token';
  static const _expiresKey = 'auth_expires_at';
  static const _userIdKey = 'user_id';
  static const _usernameKey = 'username';

  Future<void> saveSession({
    required String token,
    required DateTime expiresAt,
    required int userId,
    required String username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_expiresKey, expiresAt.toIso8601String());
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_usernameKey, username);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      return null;
    }

    final expiresRaw = prefs.getString(_expiresKey);
    if (expiresRaw != null) {
      final expires = DateTime.tryParse(expiresRaw);
      if (expires != null && DateTime.now().isAfter(expires)) {
        await clear();
        return null;
      }
    }

    return token;
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_expiresKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
  }
}
