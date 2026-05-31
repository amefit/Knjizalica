import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/auth_models.dart';
import '../models/book_models.dart';
import '../models/loan_models.dart';
import '../models/member_models.dart';
import '../models/news_models.dart';
import '../models/notification_models.dart';
import '../models/pagination_models.dart';
import '../models/recommendation_models.dart';
import '../models/reference_data_models.dart';
import '../models/reservation_models.dart';
import '../utils/api_error_parser.dart';
import 'token_storage.dart';

typedef UnauthorizedCallback = Future<void> Function();

class ApiService {
  ApiService({
    required TokenStorage tokenStorage,
    UnauthorizedCallback? onUnauthorized,
    http.Client? client,
  })  : _tokenStorage = tokenStorage,
        _onUnauthorized = onUnauthorized,
        _client = client ?? http.Client();

  final TokenStorage _tokenStorage;
  final UnauthorizedCallback? _onUnauthorized;
  final http.Client _client;

  Future<Map<String, String>> _headers({bool authenticated = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authenticated) {
      final token = await _tokenStorage.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    bool handleUnauthorized = true,
  }) async {
    final response = await request();

    if (handleUnauthorized && response.statusCode == 401) {
      await _tokenStorage.clear();
      if (_onUnauthorized != null) {
        await _onUnauthorized!();
      }
      throw ApiException(parseApiError(response), statusCode: 401);
    }

    return response;
  }

  Future<T> getJson<T>(
    String path, {
    Map<String, String>? query,
    bool authenticated = true,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiBase}$path').replace(
      queryParameters: query,
    );
    final response = await _send(
      () async => _client.get(uri, headers: await _headers(authenticated: authenticated)),
      handleUnauthorized: authenticated,
    );
    throwIfNotSuccess(response);
    return fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<T> postJson<T>(
    String path, {
    Object? body,
    bool authenticated = true,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiBase}$path');
    final response = await _send(
      () async => _client.post(
        uri,
        headers: await _headers(authenticated: authenticated),
        body: body == null ? null : jsonEncode(body),
      ),
      handleUnauthorized: authenticated,
    );
    throwIfNotSuccess(response);
    if (response.body.isEmpty) {
      return fromJson(<String, dynamic>{});
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return fromJson(decoded);
    }
    throw ApiException('Unexpected response format.');
  }

  Future<T> putJson<T>(
    String path, {
    required Object body,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiBase}$path');
    final response = await _send(
      () async => _client.put(
        uri,
        headers: await _headers(),
        body: jsonEncode(body),
      ),
    );
    throwIfNotSuccess(response);
    return fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> postEmpty(String path, {Object? body}) async {
    final uri = Uri.parse('${ApiConfig.apiBase}$path');
    final response = await _send(
      () async => _client.post(
        uri,
        headers: await _headers(),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    throwIfNotSuccess(response);
  }

  // Auth
  Future<AuthResponse> login(LoginRequest request) => postJson(
        '/auth/login',
        body: request.toJson(),
        authenticated: false,
        fromJson: AuthResponse.fromJson,
      );

  Future<AuthResponse> register(RegisterRequest request) => postJson(
        '/auth/register',
        body: request.toJson(),
        authenticated: false,
        fromJson: AuthResponse.fromJson,
      );

  Future<UserInfoResponse> getCurrentUser() => getJson(
        '/auth/me',
        fromJson: UserInfoResponse.fromJson,
      );

  Future<MessageResponse> logout() => postJson(
        '/auth/logout',
        fromJson: MessageResponse.fromJson,
      );

  Future<MessageResponse> changePassword(ChangePasswordRequest request) =>
      postJson(
        '/auth/change-password',
        body: request.toJson(),
        fromJson: MessageResponse.fromJson,
      );

  Future<MessageResponse> forgotPassword(ForgotPasswordRequest request) =>
      postJson(
        '/auth/forgot-password',
        body: request.toJson(),
        authenticated: false,
        fromJson: MessageResponse.fromJson,
      );

  Future<MessageResponse> resetPassword(ResetPasswordRequest request) =>
      postJson(
        '/auth/reset-password',
        body: request.toJson(),
        authenticated: false,
        fromJson: MessageResponse.fromJson,
      );

  // Books
  Future<PagedResult<BookListDto>> searchBooks({
    String? search,
    int? genreId,
    int? bookCategoryId,
    int page = 1,
    int pageSize = 20,
    bool? availableOnly,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
      if (search != null && search.isNotEmpty) 'search': search,
      if (genreId != null) 'genreId': '$genreId',
      if (bookCategoryId != null) 'bookCategoryId': '$bookCategoryId',
      if (availableOnly != null) 'availableOnly': availableOnly.toString(),
    };

    final response = await _send(
      () async {
        final uri = Uri.parse('${ApiConfig.apiBase}/books')
            .replace(queryParameters: query);
        return _client.get(uri, headers: await _headers());
      },
    );
    throwIfNotSuccess(response);
    return PagedResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
      BookListDto.fromJson,
    );
  }

  Future<BookDetailDto> getBook(int id) => getJson(
        '/books/$id',
        fromJson: BookDetailDto.fromJson,
      );

  // Recommendations
  Future<RecommendationsResponse> getRecommendations({int limit = 10}) =>
      getJson(
        '/recommendations',
        query: {'limit': '$limit'},
        fromJson: RecommendationsResponse.fromJson,
      );

  // Loans
  Future<PagedResult<LoanDto>> getMyLoans({
    int page = 1,
    int pageSize = 20,
    String? status,
    bool overdueOnly = false,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
      if (status != null) 'status': status,
      if (overdueOnly) 'overdueOnly': 'true',
    };

    final response = await _send(
      () async {
        final uri = Uri.parse('${ApiConfig.apiBase}/loans/my')
            .replace(queryParameters: query);
        return _client.get(uri, headers: await _headers());
      },
    );
    throwIfNotSuccess(response);
    return PagedResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
      LoanDto.fromJson,
    );
  }

  // Reservations
  Future<ReservationDto> createReservation(CreateReservationRequest request) =>
      postJson(
        '/reservations',
        body: request.toJson(),
        fromJson: ReservationDto.fromJson,
      );

  Future<AvailabilityCalendarDto> getAvailability(
    int bookCopyId,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    final query = <String, String>{
      'fromDate': fromDate.toUtc().toIso8601String(),
      'toDate': toDate.toUtc().toIso8601String(),
    };
    final response = await _send(
      () async {
        final uri =
            Uri.parse('${ApiConfig.apiBase}/reservations/availability/$bookCopyId')
                .replace(queryParameters: query);
        return _client.get(uri, headers: await _headers());
      },
    );
    throwIfNotSuccess(response);
    return AvailabilityCalendarDto.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  // Notifications
  Future<PagedResult<NotificationDto>> getNotifications({
    int page = 1,
    int pageSize = 30,
  }) async {
    final response = await _send(
      () async {
        final uri = Uri.parse('${ApiConfig.apiBase}/notifications').replace(
          queryParameters: {'page': '$page', 'pageSize': '$pageSize'},
        );
        return _client.get(uri, headers: await _headers());
      },
    );
    throwIfNotSuccess(response);
    return PagedResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
      NotificationDto.fromJson,
    );
  }

  Future<UnreadCountDto> getUnreadCount() => getJson(
        '/notifications/unread-count',
        fromJson: UnreadCountDto.fromJson,
      );

  Future<void> markNotificationRead(int id) =>
      postEmpty('/notifications/$id/read');

  Future<void> markAllNotificationsRead() => postEmpty('/notifications/read-all');

  // Members
  Future<MemberProfileDto> getMyProfile() => getJson(
        '/members/me',
        fromJson: MemberProfileDto.fromJson,
      );

  Future<MemberProfileDto> updateMyProfile(UpdateProfileRequest request) =>
      putJson(
        '/members/me',
        body: request.toJson(),
        fromJson: MemberProfileDto.fromJson,
      );

  // News
  Future<List<NewsDto>> getPublicNews() async {
    final response = await _send(
      () async {
        final uri = Uri.parse('${ApiConfig.apiBase}/news/public');
        return _client.get(uri, headers: await _headers(authenticated: false));
      },
      handleUnauthorized: false,
    );
    throwIfNotSuccess(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => NewsDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LookupDto>> getGenres() async {
    final response = await _send(
      () async => _client.get(
        Uri.parse('${ApiConfig.apiBase}/referencedata/genres'),
        headers: await _headers(),
      ),
    );
    throwIfNotSuccess(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => LookupDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LookupDto>> getBookCategories() async {
    final response = await _send(
      () async => _client.get(
        Uri.parse('${ApiConfig.apiBase}/referencedata/book-categories'),
        headers: await _headers(),
      ),
    );
    throwIfNotSuccess(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => LookupDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Reference data
  Future<List<CityDto>> getCities({int? countryId}) async {
    final response = await _send(
      () async {
        final uri = Uri.parse('${ApiConfig.apiBase}/referencedata/cities')
            .replace(
          queryParameters:
              countryId != null ? {'countryId': '$countryId'} : null,
        );
        return _client.get(uri, headers: await _headers());
      },
      handleUnauthorized: false,
    );
    throwIfNotSuccess(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => CityDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void dispose() {
    _client.close();
  }
}
