class CityDto {
  CityDto({
    required this.id,
    required this.name,
    required this.countryId,
    this.countryName,
  });

  final int id;
  final String name;
  final int countryId;
  final String? countryName;

  factory CityDto.fromJson(Map<String, dynamic> json) {
    return CityDto(
      id: json['id'] as int,
      name: json['name'] as String,
      countryId: json['countryId'] as int,
      countryName: json['countryName'] as String?,
    );
  }
}
