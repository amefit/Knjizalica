class NotificationDto {
  NotificationDto({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    return NotificationDto(
      id: json['id'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class UnreadCountDto {
  UnreadCountDto({required this.count});

  final int count;

  factory UnreadCountDto.fromJson(Map<String, dynamic> json) {
    return UnreadCountDto(count: json['count'] as int? ?? 0);
  }
}
