import 'author_models.dart';

class BookListDto {
  BookListDto({
    required this.id,
    required this.title,
    this.edition,
    this.coverImagePath,
    required this.genreName,
    required this.categoryName,
    required this.languageName,
    required this.publisherName,
    required this.totalCopies,
    required this.availableCopies,
    required this.authorNames,
  });

  final int id;
  final String title;
  final String? edition;
  final String? coverImagePath;
  final String genreName;
  final String categoryName;
  final String languageName;
  final String publisherName;
  final int totalCopies;
  final int availableCopies;
  final List<String> authorNames;

  bool get isAvailable => availableCopies > 0;

  String get authorsLabel =>
      authorNames.isEmpty ? 'Unknown author' : authorNames.join(', ');

  factory BookListDto.fromJson(Map<String, dynamic> json) {
    return BookListDto(
      id: json['id'] as int,
      title: json['title'] as String,
      edition: json['edition'] as String?,
      coverImagePath: json['coverImagePath'] as String?,
      genreName: json['genreName'] as String,
      categoryName: json['categoryName'] as String,
      languageName: json['languageName'] as String,
      publisherName: json['publisherName'] as String,
      totalCopies: json['totalCopies'] as int? ?? 0,
      availableCopies: json['availableCopies'] as int? ?? 0,
      authorNames: (json['authorNames'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class BookCopyDto {
  BookCopyDto({
    required this.id,
    required this.inventoryCode,
    required this.isAvailable,
  });

  final int id;
  final String inventoryCode;
  final bool isAvailable;

  factory BookCopyDto.fromJson(Map<String, dynamic> json) {
    return BookCopyDto(
      id: json['id'] as int,
      inventoryCode: json['inventoryCode'] as String,
      isAvailable: json['isAvailable'] as bool? ?? false,
    );
  }
}

class BookDetailDto {
  BookDetailDto({
    required this.id,
    required this.title,
    this.edition,
    this.description,
    this.coverImagePath,
    required this.genreId,
    required this.genreName,
    required this.bookCategoryId,
    required this.categoryName,
    required this.languageId,
    required this.languageName,
    required this.publisherId,
    required this.publisherName,
    required this.createdAt,
    required this.authors,
    required this.copies,
    required this.totalCopies,
    required this.availableCopies,
  });

  final int id;
  final String title;
  final String? edition;
  final String? description;
  final String? coverImagePath;
  final int genreId;
  final String genreName;
  final int bookCategoryId;
  final String categoryName;
  final int languageId;
  final String languageName;
  final int publisherId;
  final String publisherName;
  final DateTime createdAt;
  final List<AuthorDto> authors;
  final List<BookCopyDto> copies;
  final int totalCopies;
  final int availableCopies;

  bool get isAvailable => availableCopies > 0;

  String get authorsLabel =>
      authors.isEmpty ? 'Unknown author' : authors.map((a) => a.fullName).join(', ');

  factory BookDetailDto.fromJson(Map<String, dynamic> json) {
    return BookDetailDto(
      id: json['id'] as int,
      title: json['title'] as String,
      edition: json['edition'] as String?,
      description: json['description'] as String?,
      coverImagePath: json['coverImagePath'] as String?,
      genreId: json['genreId'] as int,
      genreName: json['genreName'] as String,
      bookCategoryId: json['bookCategoryId'] as int,
      categoryName: json['categoryName'] as String,
      languageId: json['languageId'] as int,
      languageName: json['languageName'] as String,
      publisherId: json['publisherId'] as int,
      publisherName: json['publisherName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      authors: (json['authors'] as List<dynamic>? ?? [])
          .map((e) => AuthorDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      copies: (json['copies'] as List<dynamic>? ?? [])
          .map((e) => BookCopyDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCopies: json['totalCopies'] as int? ?? 0,
      availableCopies: json['availableCopies'] as int? ?? 0,
    );
  }
}
