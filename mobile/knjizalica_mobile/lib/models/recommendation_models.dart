import 'book_models.dart';

class RecommendationDto {
  RecommendationDto({
    required this.book,
    required this.reason,
    required this.source,
    required this.score,
  });

  final BookListDto book;
  final String reason;
  final String source;
  final double score;

  factory RecommendationDto.fromJson(Map<String, dynamic> json) {
    return RecommendationDto(
      book: BookListDto.fromJson(json['book'] as Map<String, dynamic>),
      reason: json['reason'] as String,
      source: json['source'] as String,
      score: (json['score'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RecommendationsResponse {
  RecommendationsResponse({
    required this.contentBased,
    required this.popular,
  });

  final List<RecommendationDto> contentBased;
  final List<RecommendationDto> popular;

  factory RecommendationsResponse.fromJson(Map<String, dynamic> json) {
    return RecommendationsResponse(
      contentBased: (json['contentBased'] as List<dynamic>? ?? [])
          .map((e) => RecommendationDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      popular: (json['popular'] as List<dynamic>? ?? [])
          .map((e) => RecommendationDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
