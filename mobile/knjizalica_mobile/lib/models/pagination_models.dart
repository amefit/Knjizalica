class PagedResult<T> {
  PagedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return PagedResult(
      items: rawItems
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }
}

class LookupDto {
  LookupDto({required this.id, required this.name});

  final int id;
  final String name;

  factory LookupDto.fromJson(Map<String, dynamic> json) {
    return LookupDto(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class MessageResponse {
  MessageResponse({required this.message});

  final String message;

  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    return MessageResponse(message: json['message'] as String);
  }
}

class ErrorResponse {
  ErrorResponse({required this.message, this.details});

  final String message;
  final String? details;

  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    return ErrorResponse(
      message: json['message'] as String? ?? 'An error occurred.',
      details: json['details'] as String?,
    );
  }
}
