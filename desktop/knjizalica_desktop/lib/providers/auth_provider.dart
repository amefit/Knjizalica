import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  AuthStatus status = AuthStatus.unknown;
  UserInfo? user;
  String? error;
  bool isLoading = false;

  AuthService get authService => _authService;

  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();

    try {
      user = await _authService.restoreSession();
      status =
          user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      error = null;
    } catch (e) {
      status = AuthStatus.unauthenticated;
      user = null;
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _authService.login(username, password);
      user = response.user;
      status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      error = e.message;
      status = AuthStatus.unauthenticated;
      return false;
    } catch (e) {
      error = 'Unable to connect to the server. Please try again.';
      status = AuthStatus.unauthenticated;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<String?> getSavedUsername() => _authService.getSavedUsername();
}
