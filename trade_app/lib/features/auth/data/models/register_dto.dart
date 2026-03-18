import 'user_dto.dart';

/// Register request model (DTO)
class RegisterRequestModel {
  final String email;
  final String password;
  final String name;
  final String? phone;
  final String? location;
  final String? profileImage;

  const RegisterRequestModel({
    required this.email,
    required this.password,
    required this.name,
    this.phone,
    this.location,
    this.profileImage,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'name': name,
      if (phone != null) 'phone': phone,
      if (location != null) 'location': location,
      if (profileImage != null) 'profileImage': profileImage,
    };
  }
}

/// Register response model (DTO)
class RegisterResponseModel {
  final UserModel user;
  final String? token;
  final String? refreshToken;
  final String? message;

  const RegisterResponseModel({
    required this.user,
    this.token,
    this.refreshToken,
    this.message,
  });

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    return RegisterResponseModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String?,
      refreshToken: json['refreshToken'] as String?,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      if (token != null) 'token': token,
      if (refreshToken != null) 'refreshToken': refreshToken,
      if (message != null) 'message': message,
    };
  }
}
