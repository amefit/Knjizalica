import '../models/models.dart';
import 'api_service.dart';
import 'token_storage.dart';

class AuthService {
  AuthService({
    ApiService? apiService,
    TokenStorage? tokenStorage,
  })  : _api = apiService ?? ApiService(),
        _tokenStorage = tokenStorage ?? TokenStorage() {
    _api.setTokenProvider(() => _tokenStorage.getToken());
  }

  final ApiService _api;
  final TokenStorage _tokenStorage;

  ApiService get api => _api;

  Future<AuthResponse> login(String username, String password) async {
    final response = await _api.login(username, password);
    if (!response.user.isAdmin) {
      throw ApiException('Access denied. Admin credentials required.');
    }
    await _tokenStorage.saveToken(response.token, response.expiresAt);
    await _tokenStorage.saveUsername(response.user.username);
    return response;
  }

  Future<UserInfo?> restoreSession() async {
    final token = await _tokenStorage.getToken();
    if (token == null) return null;

    try {
      final user = await _api.getCurrentUser();
      if (!user.isAdmin) {
        await logout();
        return null;
      }
      return user;
    } catch (_) {
      await logout();
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } finally {
      await _tokenStorage.clear();
    }
  }

  Future<String?> getSavedUsername() => _tokenStorage.getUsername();
}
