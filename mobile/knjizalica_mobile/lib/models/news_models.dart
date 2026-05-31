class NewsDto {
  NewsDto({
    required this.id,
    required this.title,
    required this.content,
    this.imagePath,
    required this.publishedAt,
    required this.isActive,
  });

  final int id;
  final String title;
  final String content;
  final String? imagePath;
  final DateTime publishedAt;
  final bool isActive;

  factory NewsDto.fromJson(Map<String, dynamic> json) {
    return NewsDto(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      imagePath: json['imagePath'] as String?,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
