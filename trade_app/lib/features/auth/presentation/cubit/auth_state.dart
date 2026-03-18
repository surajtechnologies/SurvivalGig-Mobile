import 'package:equatable/equatable.dart';

/// Base auth state
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Login success state
class LoginSuccess extends AuthState {
  final String userId;
  final String userName;

  const LoginSuccess({required this.userId, required this.userName});

  @override
  List<Object?> get props => [userId, userName];
}

/// Register success state
class RegisterSuccess extends AuthState {
  final String userId;
  final String userName;
  final String? message;

  const RegisterSuccess({
    required this.userId,
    required this.userName,
    this.message,
  });

  @override
  List<Object?> get props => [userId, userName, message];
}

/// Forgot password success state
class ForgotPasswordSuccess extends AuthState {
  final String message;

  const ForgotPasswordSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Auth failure state
class AuthFailure extends AuthState {
  final String message;
  final String? code;

  const AuthFailure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Profile image upload success
class ProfileImageUploadSuccess extends AuthState {
  final String imageUrl;

  const ProfileImageUploadSuccess({required this.imageUrl});

  @override
  List<Object?> get props => [imageUrl];
}

/// Device token registration success
class DeviceTokenRegistered extends AuthState {
  final String message;

  const DeviceTokenRegistered({required this.message});

  @override
  List<Object?> get props => [message];
}
