class AuthorDto {
  AuthorDto({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.biography,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String? biography;

  String get fullName => '$firstName $lastName';

  factory AuthorDto.fromJson(Map<String, dynamic> json) {
    return AuthorDto(
      id: json['id'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      biography: json['biography'] as String?,
    );
  }
}
