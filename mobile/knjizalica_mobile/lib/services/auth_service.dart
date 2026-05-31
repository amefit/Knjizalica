import '../models/auth_models.dart';
import 'api_service.dart';
import 'token_storage.dart';

class AuthService {
  AuthService({
    required ApiService api,
    required TokenStorage tokenStorage,
  })  : _api = api,
        _tokenStorage = tokenStorage;

  final ApiService _api;
  final TokenStorage _tokenStorage;

  Future<AuthResponse> login(String username, String password) async {
    final response = await _api.login(
      LoginRequest(username: username, password: password),
    );
    await _persist(response);
    return response;
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await _api.register(request);
    await _persist(response);
    return response;
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {
      // Clear local session even if remote logout fails.
    }
    await _tokenStorage.clear();
  }

  Future<bool> hasValidSession() async {
    final token = await _tokenStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<UserInfoResponse?> restoreUser() async {
    if (!await hasValidSession()) {
      return null;
    }
    try {
      return await _api.getCurrentUser();
    } catch (_) {
      await _tokenStorage.clear();
      return null;
    }
  }

  Future<void> _persist(AuthResponse response) async {
    await _tokenStorage.saveSession(
      token: response.token,
      expiresAt: response.expiresAt,
      userId: response.user.id,
      username: response.user.username,
    );
  }
}
