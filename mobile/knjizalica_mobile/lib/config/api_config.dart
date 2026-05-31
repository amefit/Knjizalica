class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

  static const String apiPrefix = '/api';

  static String get apiBase => '$baseUrl$apiPrefix';

  static String get hubUrl => '$baseUrl/hubs/notifications';

  /// Bumped when seed/static assets change so CachedNetworkImage refetches covers.
  static const String mediaCacheVersion = '2';

  static String resolveMediaUrl(String? path) {
    if (path == null || path.isEmpty) {
      return '';
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final normalized = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$normalized?v=$mediaCacheVersion';
  }
}
