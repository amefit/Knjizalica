import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import '../models/models.dart';
import 'token_storage.dart';

typedef TokenProvider = Future<String?> Function();

class ApiService {
  ApiService({TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage();

  final TokenStorage _tokenStorage;
  TokenProvider? _tokenProvider;

  void setTokenProvider(TokenProvider provider) {
    _tokenProvider = provider;
  }

  Future<String?> _resolveToken() async {
    if (_tokenProvider != null) {
      return _tokenProvider!();
    }
    return _tokenStorage.getToken();
  }

  Future<Map<String, String>> _headers({bool json = true, bool auth = true}) async {
    final headers = <String, String>{
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth) {
      final token = await _resolveToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    throw _parseError(response);
  }

  ApiException _parseError(http.Response response) {
    String message = 'Request failed (${response.statusCode})';
    String? details;

    if (response.body.isNotEmpty) {
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          message = body['message'] as String? ??
              body['title'] as String? ??
              message;
          details = body['details'] as String?;
        }
      } catch (_) {
        message = response.body;
      }
    }

    if (response.statusCode == 401) {
      message = message == 'Request failed (401)'
          ? 'Session expired. Please sign in again.'
          : message;
    }

    return ApiException(message, statusCode: response.statusCode, details: details);
  }

  String _buildQuery(Map<String, dynamic> params) {
    final entries = params.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value.toString())}')
        .join('&');
    return entries.isEmpty ? '' : '?$entries';
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) async {
    final uri = Uri.parse('${ApiConfig.apiUrl}$path${_buildQuery(query ?? {})}');
    final response = await http.get(uri, headers: await _headers(auth: auth));
    return _handleResponse(response);
  }

  Future<dynamic> post(String path, {Object? body, bool auth = true}) async {
    final uri = Uri.parse('${ApiConfig.apiUrl}$path');
    final response = await http.post(
      uri,
      headers: await _headers(auth: auth),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String path, {required Object body}) async {
    final uri = Uri.parse('${ApiConfig.apiUrl}$path');
    final response = await http.put(
      uri,
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('${ApiConfig.apiUrl}$path');
    final response = await http.delete(uri, headers: await _headers());
    return _handleResponse(response);
  }

  Future<Uint8List> downloadBytes(String path, {Map<String, dynamic>? query}) async {
    final uri = Uri.parse('${ApiConfig.apiUrl}$path${_buildQuery(query ?? {})}');
    final response = await http.get(uri, headers: await _headers(json: false));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    throw _parseError(response);
  }

  Future<FileUploadResult> uploadFile({
    required String filePath,
    required String fileName,
    String category = 'books',
  }) async {
    final uri = Uri.parse('${ApiConfig.apiUrl}/files/upload?category=$category');
    final request = http.MultipartRequest('POST', uri);

    final token = await _resolveToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final lower = fileName.toLowerCase();
    MediaType? contentType;
    if (lower.endsWith('.png')) {
      contentType = MediaType('image', 'png');
    } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      contentType = MediaType('image', 'jpeg');
    } else if (lower.endsWith('.webp')) {
      contentType = MediaType('image', 'webp');
    }

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      filePath,
      filename: fileName,
      contentType: contentType,
    ));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final data = await _handleResponse(response);
    return FileUploadResult.fromJson(data as Map<String, dynamic>);
  }

  // Auth
  Future<AuthResponse> login(String username, String password) async {
    final data = await post(
      '/auth/login',
      body: {'username': username, 'password': password},
      auth: false,
    );
    return AuthResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<UserInfo> getCurrentUser() async {
    final data = await get('/auth/me');
    return UserInfo.fromJson(data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await post('/auth/logout');
    } catch (_) {}
  }

  // Dashboard
  Future<DashboardData> getDashboard() async {
    final data = await get('/dashboard');
    return DashboardData.fromJson(data as Map<String, dynamic>);
  }

  // Books
  Future<PagedResult<BookListItem>> getBooks({
    int page = 1,
    int pageSize = 20,
    String? search,
    int? genreId,
    int? bookCategoryId,
    int? languageId,
    int? publisherId,
    int? authorId,
    bool? availableOnly,
  }) async {
    final data = await get('/books', query: {
      'page': page,
      'pageSize': pageSize,
      'search': search,
      'genreId': genreId,
      'bookCategoryId': bookCategoryId,
      'languageId': languageId,
      'publisherId': publisherId,
      'authorId': authorId,
      'availableOnly': availableOnly,
    });
    return PagedResult.fromJson(
      data as Map<String, dynamic>,
      (json) => BookListItem.fromJson(json),
    );
  }

  Future<BookDetail> getBook(int id) async {
    final data = await get('/books/$id');
    return BookDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<BookDetail> createBook(Map<String, dynamic> body) async {
    final data = await post('/books', body: body);
    return BookDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<BookDetail> updateBook(int id, Map<String, dynamic> body) async {
    final data = await put('/books/$id', body: body);
    return BookDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteBook(int id) async {
    await delete('/books/$id');
  }

  // Authors
  Future<List<Author>> getAuthors({int pageSize = 200}) async {
    final data = await get('/authors', query: {'page': 1, 'pageSize': pageSize});
    if (data is Map<String, dynamic> && data.containsKey('items')) {
      return (data['items'] as List<dynamic>)
          .map((e) => Author.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is List) {
      return data.map((e) => Author.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<Author> createAuthor(Map<String, dynamic> body) async {
    final data = await post('/authors', body: body);
    return Author.fromJson(data as Map<String, dynamic>);
  }

  Future<Author> updateAuthor(int id, Map<String, dynamic> body) async {
    final data = await put('/authors/$id', body: body);
    return Author.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteAuthor(int id) async {
    await delete('/authors/$id');
  }

  // Loans
  Future<PagedResult<Loan>> getLoans({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    bool overdueOnly = false,
  }) async {
    final data = await get('/loans', query: {
      'page': page,
      'pageSize': pageSize,
      'search': search,
      'status': status,
      'overdueOnly': overdueOnly ? true : null,
    });
    return PagedResult.fromJson(
      data as Map<String, dynamic>,
      (json) => Loan.fromJson(json),
    );
  }

  Future<PagedResult<Loan>> getOverdueLoans({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    final data = await get('/loans/overdue', query: {
      'page': page,
      'pageSize': pageSize,
      'search': search,
    });
    return PagedResult.fromJson(
      data as Map<String, dynamic>,
      (json) => Loan.fromJson(json),
    );
  }

  Future<Loan> createLoan(Map<String, dynamic> body) async {
    final data = await post('/loans', body: body);
    return Loan.fromJson(data as Map<String, dynamic>);
  }

  Future<Loan> confirmLoan(int id) async {
    final data = await post('/loans/$id/confirm');
    return Loan.fromJson(data as Map<String, dynamic>);
  }

  Future<Loan> returnLoan(int id) async {
    final data = await post('/loans/$id/return');
    return Loan.fromJson(data as Map<String, dynamic>);
  }

  Future<Loan> cancelLoan(int id, {String? reason}) async {
    final data = await post('/loans/$id/cancel', body: {'reason': reason});
    return Loan.fromJson(data as Map<String, dynamic>);
  }

  // Members
  Future<PagedResult<Member>> getMembers({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? tab,
  }) async {
    final data = await get('/members', query: {
      'page': page,
      'pageSize': pageSize,
      'search': search,
      'tab': tab,
    });
    return PagedResult.fromJson(
      data as Map<String, dynamic>,
      (json) => Member.fromJson(json),
    );
  }

  Future<Member> createMember(Map<String, dynamic> body) async {
    final data = await post('/members', body: body);
    return Member.fromJson(data as Map<String, dynamic>);
  }

  Future<Member> updateMember(int id, Map<String, dynamic> body) async {
    final data = await put('/members/$id', body: body);
    return Member.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteMember(int id) async {
    await delete('/members/$id');
  }

  Future<void> blockMember(int id) async {
    await post('/members/$id/block');
  }

  Future<void> unblockMember(int id) async {
    await post('/members/$id/unblock');
  }

  // Reservations
  Future<PagedResult<Reservation>> getReservations({
    int page = 1,
    int pageSize = 10,
    String? status,
    String? search,
  }) async {
    final data = await get('/reservations', query: {
      'page': page,
      'pageSize': pageSize,
      'status': status,
      'search': search,
    });
    return PagedResult.fromJson(
      data as Map<String, dynamic>,
      (json) => Reservation.fromJson(json),
    );
  }

  Future<Reservation> confirmReservation(int id) async {
    final data = await post('/reservations/$id/confirm');
    return Reservation.fromJson(data as Map<String, dynamic>);
  }

  // Activity logs
  Future<PagedResult<ActivityLog>> getActivityLogs({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? activityType,
    String? entityName,
  }) async {
    final data = await get('/activitylogs', query: {
      'page': page,
      'pageSize': pageSize,
      'search': search,
      'activityType': activityType,
      'entityName': entityName,
    });
    return PagedResult.fromJson(
      data as Map<String, dynamic>,
      (json) => ActivityLog.fromJson(json),
    );
  }

  // Reference data
  Future<List<Country>> getCountries() async {
    final data = await get('/referencedata/countries');
    return (data as List<dynamic>)
        .map((e) => Country.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Country> createCountry(String name) async {
    final data = await post('/referencedata/countries', body: {'name': name});
    return Country.fromJson(data as Map<String, dynamic>);
  }

  Future<Country> updateCountry(int id, String name) async {
    final data = await put('/referencedata/countries/$id', body: {'name': name});
    return Country.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteCountry(int id) async {
    await delete('/referencedata/countries/$id');
  }

  Future<List<City>> getCities() async {
    final data = await get('/referencedata/cities');
    return (data as List<dynamic>)
        .map((e) => City.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<City> createCity(String name, int countryId) async {
    final data = await post('/referencedata/cities', body: {
      'name': name,
      'countryId': countryId,
    });
    return City.fromJson(data as Map<String, dynamic>);
  }

  Future<City> updateCity(int id, String name, int countryId) async {
    final data = await put('/referencedata/cities/$id', body: {
      'name': name,
      'countryId': countryId,
    });
    return City.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteCity(int id) async {
    await delete('/referencedata/cities/$id');
  }

  Future<List<LookupItem>> getGenres() async {
    final data = await get('/referencedata/genres');
    return (data as List<dynamic>)
        .map((e) => LookupItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LookupItem> createGenre(String name) async {
    final data = await post('/referencedata/genres', body: {'name': name});
    return LookupItem.fromJson(data as Map<String, dynamic>);
  }

  Future<LookupItem> updateGenre(int id, String name) async {
    final data = await put('/referencedata/genres/$id', body: {'name': name});
    return LookupItem.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteGenre(int id) async {
    await delete('/referencedata/genres/$id');
  }

  Future<List<LookupItem>> getBookCategories() async {
    final data = await get('/referencedata/book-categories');
    return (data as List<dynamic>)
        .map((e) => LookupItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LookupItem> createBookCategory(String name) async {
    final data = await post('/referencedata/book-categories', body: {'name': name});
    return LookupItem.fromJson(data as Map<String, dynamic>);
  }

  Future<LookupItem> updateBookCategory(int id, String name) async {
    final data = await put('/referencedata/book-categories/$id', body: {'name': name});
    return LookupItem.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteBookCategory(int id) async {
    await delete('/referencedata/book-categories/$id');
  }

  Future<List<LookupItem>> getLanguages() async {
    final data = await get('/referencedata/languages');
    return (data as List<dynamic>)
        .map((e) => LookupItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LookupItem> createLanguage(String name) async {
    final data = await post('/referencedata/languages', body: {'name': name});
    return LookupItem.fromJson(data as Map<String, dynamic>);
  }

  Future<LookupItem> updateLanguage(int id, String name) async {
    final data = await put('/referencedata/languages/$id', body: {'name': name});
    return LookupItem.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteLanguage(int id) async {
    await delete('/referencedata/languages/$id');
  }

  Future<List<LookupItem>> getPublishers() async {
    final data = await get('/referencedata/publishers');
    return (data as List<dynamic>)
        .map((e) => LookupItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LookupItem> createPublisher(String name) async {
    final data = await post('/referencedata/publishers', body: {'name': name});
    return LookupItem.fromJson(data as Map<String, dynamic>);
  }

  Future<LookupItem> updatePublisher(int id, String name) async {
    final data = await put('/referencedata/publishers/$id', body: {'name': name});
    return LookupItem.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deletePublisher(int id) async {
    await delete('/referencedata/publishers/$id');
  }

  Future<List<LookupItem>> getMembershipStatuses() async {
    final data = await get('/referencedata/membership-statuses');
    return (data as List<dynamic>)
        .map((e) => LookupItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LookupItem> createMembershipStatus(String name) async {
    final data = await post('/referencedata/membership-statuses', body: {'name': name});
    return LookupItem.fromJson(data as Map<String, dynamic>);
  }

  Future<LookupItem> updateMembershipStatus(int id, String name) async {
    final data = await put('/referencedata/membership-statuses/$id', body: {'name': name});
    return LookupItem.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteMembershipStatus(int id) async {
    await delete('/referencedata/membership-statuses/$id');
  }

  Future<List<LookupItem>> getLoanStatuses() async {
    final data = await get('/referencedata/loan-statuses');
    return (data as List<dynamic>)
        .map((e) => LookupItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LookupItem> createLoanStatus(String name) async {
    final data = await post('/referencedata/loan-statuses', body: {'name': name});
    return LookupItem.fromJson(data as Map<String, dynamic>);
  }

  Future<LookupItem> updateLoanStatus(int id, String name) async {
    final data = await put('/referencedata/loan-statuses/$id', body: {'name': name});
    return LookupItem.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteLoanStatus(int id) async {
    await delete('/referencedata/loan-statuses/$id');
  }

  Future<List<LookupItem>> getReservationStatuses() async {
    final data = await get('/referencedata/reservation-statuses');
    return (data as List<dynamic>)
        .map((e) => LookupItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LookupItem> createReservationStatus(String name) async {
    final data = await post('/referencedata/reservation-statuses', body: {'name': name});
    return LookupItem.fromJson(data as Map<String, dynamic>);
  }

  Future<LookupItem> updateReservationStatus(int id, String name) async {
    final data = await put('/referencedata/reservation-statuses/$id', body: {'name': name});
    return LookupItem.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteReservationStatus(int id) async {
    await delete('/referencedata/reservation-statuses/$id');
  }

  Future<List<LookupItem>> getActivityTypes() async {
    final data = await get('/referencedata/activity-types');
    return (data as List<dynamic>)
        .map((e) => LookupItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LookupItem> createActivityType(String name) async {
    final data = await post('/referencedata/activity-types', body: {'name': name});
    return LookupItem.fromJson(data as Map<String, dynamic>);
  }

  Future<LookupItem> updateActivityType(int id, String name) async {
    final data = await put('/referencedata/activity-types/$id', body: {'name': name});
    return LookupItem.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteActivityType(int id) async {
    await delete('/referencedata/activity-types/$id');
  }

  // News
  Future<List<NewsItem>> getNews({String? search, bool? isActive}) async {
    final query = <String, String>{
      'page': '1',
      'pageSize': '100',
      if (search != null && search.isNotEmpty) 'search': search,
      if (isActive != null) 'isActive': isActive.toString(),
    };
    final data = await get('/news', query: query);
    final items = (data as Map<String, dynamic>)['items'] as List<dynamic>? ?? [];
    return items.map((e) => NewsItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<NewsItem> createNews(Map<String, dynamic> body) async {
    final data = await post('/news', body: body);
    return NewsItem.fromJson(data as Map<String, dynamic>);
  }

  Future<NewsItem> updateNews(int id, Map<String, dynamic> body) async {
    final data = await put('/news/$id', body: body);
    return NewsItem.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteNews(int id) async {
    await delete('/news/$id');
  }

  // Reports
  Future<Uint8List> downloadOverdueLoansReport() async {
    return downloadBytes('/reports/overdue-loans');
  }

  Future<Uint8List> downloadLoansByPeriodReport(DateTime from, DateTime to) async {
    return downloadBytes('/reports/loans-by-period', query: {
      'fromDate': from.toUtc().toIso8601String(),
      'toDate': to.toUtc().toIso8601String(),
    });
  }
}
