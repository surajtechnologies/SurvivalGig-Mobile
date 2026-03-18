import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/send_password_reset_email_usecase.dart';
import 'reset_password_state.dart';

/// Reset password cubit
class ResetPasswordCubit extends Cubit<ResetPasswordState> {
  final SendPasswordResetEmailUseCase sendPasswordResetEmailUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;

  ResetPasswordCubit({
    required this.sendPasswordResetEmailUseCase,
    required this.resetPasswordUseCase,
  }) : super(const ResetPasswordInitial());

  /// Initialize with email and immediately send reset email
  Future<void> initialize({required String email}) async {
    emit(
      ResetPasswordLoaded(
        email: email,
        isSendingEmail: true,
        statusMessage: null,
        isStatusError: false,
      ),
    );

    final result = await sendPasswordResetEmailUseCase(email: email);
    result.fold(
      (failure) {
        emit(
          ResetPasswordLoaded(
            email: email,
            isSendingEmail: false,
            statusMessage: failure.message,
            isStatusError: true,
          ),
        );
      },
      (message) {
        emit(
          ResetPasswordLoaded(
            email: email,
            isSendingEmail: false,
            statusMessage: message,
            isStatusError: false,
          ),
        );
      },
    );
  }

  /// Resend reset email
  Future<void> resendEmail() async {
    final currentState = state;
    if (currentState is! ResetPasswordLoaded) {
      return;
    }

    emit(
      currentState.copyWith(
        isSendingEmail: true,
        clearStatusMessage: true,
        isStatusError: false,
      ),
    );

    final result = await sendPasswordResetEmailUseCase(
      email: currentState.email,
    );
    result.fold(
      (failure) {
        emit(
          currentState.copyWith(
            isSendingEmail: false,
            statusMessage: failure.message,
            isStatusError: true,
          ),
        );
      },
      (message) {
        emit(
          currentState.copyWith(
            isSendingEmail: false,
            statusMessage: message,
            isStatusError: false,
          ),
        );
      },
    );
  }

  /// Submit new password with token
  Future<void> updatePassword({
    required String token,
    required String password,
  }) async {
    final currentState = state;
    if (currentState is! ResetPasswordLoaded) {
      return;
    }

    final normalizedToken = token.trim();
    final normalizedPassword = password.trim();

    if (normalizedToken.isEmpty) {
      emit(
        currentState.copyWith(
          isStatusError: true,
          statusMessage: 'Verification token is required',
        ),
      );
      return;
    }

    if (normalizedPassword.isEmpty) {
      emit(
        currentState.copyWith(
          isStatusError: true,
          statusMessage: 'New password is required',
        ),
      );
      return;
    }

    if (!_isPasswordStrong(normalizedPassword)) {
      emit(
        currentState.copyWith(
          isStatusError: true,
          statusMessage:
              'Password must include letters, numbers, and special characters',
        ),
      );
      return;
    }

    emit(
      currentState.copyWith(
        isUpdatingPassword: true,
        clearStatusMessage: true,
        isStatusError: false,
      ),
    );

    final result = await resetPasswordUseCase(
      token: normalizedToken,
      password: normalizedPassword,
    );

    result.fold(
      (failure) {
        emit(
          currentState.copyWith(
            isUpdatingPassword: false,
            statusMessage: failure.message,
            isStatusError: true,
          ),
        );
      },
      (message) {
        emit(ResetPasswordSuccess(message: message));
      },
    );
  }

  /// Clear one-time status message after UI shows toast/snackbar
  void clearStatusMessage() {
    final currentState = state;
    if (currentState is ResetPasswordLoaded &&
        currentState.statusMessage != null) {
      emit(currentState.copyWith(clearStatusMessage: true));
    }
  }

  static bool _isPasswordStrong(String password) {
    if (password.length < 8) {
      return false;
    }

    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecial = RegExp(r'[^A-Za-z0-9]').hasMatch(password);
    return hasLetter && hasNumber && hasSpecial;
  }
}
