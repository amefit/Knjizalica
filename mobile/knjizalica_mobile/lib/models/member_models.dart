class MemberProfileDto {
  MemberProfileDto({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    required this.memberCardNumber,
    required this.membershipStatus,
    required this.cityId,
    required this.cityName,
    this.profileImagePath,
    required this.registrationDate,
    required this.expiryDate,
  });

  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String memberCardNumber;
  final String membershipStatus;
  final int cityId;
  final String cityName;
  final String? profileImagePath;
  final DateTime registrationDate;
  final DateTime expiryDate;

  String get fullName => '$firstName $lastName';

  factory MemberProfileDto.fromJson(Map<String, dynamic> json) {
    return MemberProfileDto(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      memberCardNumber: json['memberCardNumber'] as String,
      membershipStatus: json['membershipStatus'] as String,
      cityId: json['cityId'] as int,
      cityName: json['cityName'] as String,
      profileImagePath: json['profileImagePath'] as String?,
      registrationDate: DateTime.parse(json['registrationDate'] as String),
      expiryDate: DateTime.parse(json['expiryDate'] as String),
    );
  }
}

class UpdateProfileRequest {
  UpdateProfileRequest({
    required this.firstName,
    required this.lastName,
    required this.cityId,
    this.phoneNumber,
    this.profileImagePath,
  });

  final String firstName;
  final String lastName;
  final int cityId;
  final String? phoneNumber;
  final String? profileImagePath;

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'cityId': cityId,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (profileImagePath != null) 'profileImagePath': profileImagePath,
      };
}
