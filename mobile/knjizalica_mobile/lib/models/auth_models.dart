class LoginRequest {
  LoginRequest({required this.username, required this.password});

  final String username;
  final String password;

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };
}

class RegisterRequest {
  RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    required this.password,
    required this.confirmPassword,
    required this.cityId,
    this.phoneNumber,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final String password;
  final String confirmPassword;
  final int cityId;
  final String? phoneNumber;

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'username': username,
        'password': password,
        'confirmPassword': confirmPassword,
        'cityId': cityId,
        if (phoneNumber != null && phoneNumber!.isNotEmpty)
          'phoneNumber': phoneNumber,
      };
}

class AuthResponse {
  AuthResponse({
    required this.token,
    required this.expiresAt,
    required this.user,
  });

  final String token;
  final DateTime expiresAt;
  final UserInfoResponse user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      user: UserInfoResponse.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class UserInfoResponse {
  UserInfoResponse({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.roles,
  });

  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final List<String> roles;

  String get fullName => '$firstName $lastName';

  factory UserInfoResponse.fromJson(Map<String, dynamic> json) {
    return UserInfoResponse(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      roles: (json['roles'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class ChangePasswordRequest {
  ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  Map<String, dynamic> toJson() => {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      };
}

class ForgotPasswordRequest {
  ForgotPasswordRequest({required this.email});

  final String email;

  Map<String, dynamic> toJson() => {'email': email};
}

class ResetPasswordRequest {
  ResetPasswordRequest({
    required this.email,
    required this.token,
    required this.newPassword,
    required this.confirmPassword,
  });

  final String email;
  final String token;
  final String newPassword;
  final String confirmPassword;

  Map<String, dynamic> toJson() => {
        'email': email,
        'token': token,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      };
}
