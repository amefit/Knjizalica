import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/member_models.dart';
import '../models/reference_data_models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_hub_service.dart';
import '../services/token_storage.dart';
import '../utils/api_error_parser.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthService authService,
    required ApiService apiService,
    required NotificationHubService hubService,
    required TokenStorage tokenStorage,
  })  : _authService = authService,
        _api = apiService,
        _hubService = hubService,
        _tokenStorage = tokenStorage;

  final AuthService _authService;
  final ApiService _api;
  final NotificationHubService _hubService;
  final TokenStorage _tokenStorage;

  AuthStatus status = AuthStatus.unknown;
  UserInfoResponse? user;
  MemberProfileDto? profile;
  List<CityDto> cities = [];
  String? errorMessage;
  bool isLoading = false;

  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();

    final restored = await _authService.restoreUser();
    if (restored != null) {
      user = restored;
      status = AuthStatus.authenticated;
      await _loadProfileAndHub();
    } else {
      status = AuthStatus.unauthenticated;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(username, password);
      user = response.user;
      status = AuthStatus.authenticated;
      await _loadProfileAndHub();
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e is ApiException ? e.message : e.toString();
      status = AuthStatus.unauthenticated;
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(RegisterRequest request) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.register(request);
      user = response.user;
      status = AuthStatus.authenticated;
      await _loadProfileAndHub();
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e is ApiException ? e.message : e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _hubService.disconnect();
    await _authService.logout();
    user = null;
    profile = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> handleUnauthorized() async {
    await _hubService.disconnect();
    user = null;
    profile = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      profile = await _api.getMyProfile();
      notifyListeners();
    } catch (_) {
      // Profile refresh is best-effort.
    }
  }

  Future<bool> updateProfile(UpdateProfileRequest request) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      profile = await _api.updateMyProfile(request);
      if (user != null) {
        user = UserInfoResponse(
          id: user!.id,
          username: user!.username,
          email: user!.email,
          firstName: request.firstName,
          lastName: request.lastName,
          roles: user!.roles,
        );
      }
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e is ApiException ? e.message : e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(ChangePasswordRequest request) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _api.changePassword(request);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e is ApiException ? e.message : e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> forgotPassword(String email) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.forgotPassword(ForgotPasswordRequest(email: email));
      isLoading = false;
      notifyListeners();
      return response.message;
    } catch (e) {
      errorMessage = e is ApiException ? e.message : e.toString();
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> resetPassword(ResetPasswordRequest request) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _api.resetPassword(request);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e is ApiException ? e.message : e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadCities({bool silent = false}) async {
    try {
      cities = await _api.getCities();
      notifyListeners();
    } catch (e) {
      if (!silent) {
        errorMessage = e is ApiException ? e.message : e.toString();
        notifyListeners();
      }
    }
  }

  Future<void> _loadProfileAndHub() async {
    await refreshProfile();
    try {
      await _hubService.connect(_tokenStorage);
    } catch (_) {
      // Hub connection is optional at startup.
    }
  }
}
