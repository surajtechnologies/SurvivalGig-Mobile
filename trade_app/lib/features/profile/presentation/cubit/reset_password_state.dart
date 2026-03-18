import 'package:equatable/equatable.dart';

/// Reset password state
abstract class ResetPasswordState extends Equatable {
  const ResetPasswordState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ResetPasswordInitial extends ResetPasswordState {
  const ResetPasswordInitial();
}

/// Loaded/form state
class ResetPasswordLoaded extends ResetPasswordState {
  final String email;
  final bool isSendingEmail;
  final bool isUpdatingPassword;
  final String? statusMessage;
  final bool isStatusError;

  const ResetPasswordLoaded({
    required this.email,
    this.isSendingEmail = false,
    this.isUpdatingPassword = false,
    this.statusMessage,
    this.isStatusError = false,
  });

  ResetPasswordLoaded copyWith({
    String? email,
    bool? isSendingEmail,
    bool? isUpdatingPassword,
    String? statusMessage,
    bool? isStatusError,
    bool clearStatusMessage = false,
  }) {
    return ResetPasswordLoaded(
      email: email ?? this.email,
      isSendingEmail: isSendingEmail ?? this.isSendingEmail,
      isUpdatingPassword: isUpdatingPassword ?? this.isUpdatingPassword,
      statusMessage: clearStatusMessage
          ? null
          : (statusMessage ?? this.statusMessage),
      isStatusError: isStatusError ?? this.isStatusError,
    );
  }

  @override
  List<Object?> get props => [
    email,
    isSendingEmail,
    isUpdatingPassword,
    statusMessage,
    isStatusError,
  ];
}

/// Password reset completed successfully
class ResetPasswordSuccess extends ResetPasswordState {
  final String message;

  const ResetPasswordSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Error state
class ResetPasswordError extends ResetPasswordState {
  final String email;
  final String message;
  final String? code;

  const ResetPasswordError({
    required this.email,
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [email, message, code];
}
