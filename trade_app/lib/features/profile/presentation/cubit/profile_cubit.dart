import 'dart:convert';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/send_password_reset_email_usecase.dart';
import '../../domain/usecases/upload_profile_image_usecase.dart';
import '../../domain/usecases/verify_profile_usecase.dart';
import 'profile_state.dart';

/// Profile cubit
class ProfileCubit extends Cubit<ProfileState> {
  final GetProfileUseCase getProfileUseCase;
  final UploadProfileImageUseCase uploadProfileImageUseCase;
  final VerifyProfileUseCase verifyProfileUseCase;
  final SendPasswordResetEmailUseCase sendPasswordResetEmailUseCase;

  ProfileCubit({
    required this.getProfileUseCase,
    required this.uploadProfileImageUseCase,
    required this.verifyProfileUseCase,
    required this.sendPasswordResetEmailUseCase,
  }) : super(const ProfileInitial());

  /// Load profile data from /users/me endpoint
  Future<void> loadProfile({bool showLoading = true}) async {
    if (showLoading) {
      emit(const ProfileLoading());
    }

    final result = await getProfileUseCase();

    result.fold(
      (failure) {
        emit(ProfileError(message: failure.message, code: failure.code));
      },
      (profile) {
        emit(ProfileLoaded(profile: profile));
      },
    );
  }

  /// Pull to refresh profile
  Future<void> refresh() async {
    await loadProfile(showLoading: state is! ProfileLoaded);
  }

  /// Upload profile image from local file path
  Future<void> uploadProfileImage(String filePath) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) {
      return;
    }

    emit(
      currentState.copyWith(
        isUploadingImage: true,
        clearStatusMessage: true,
        isStatusError: false,
      ),
    );

    final file = File(filePath);
    if (!await file.exists()) {
      emit(
        currentState.copyWith(
          isUploadingImage: false,
          statusMessage: 'Image file not found',
          isStatusError: true,
        ),
      );
      return;
    }

    try {
      final bytes = await file.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      final result = await uploadProfileImageUseCase(base64Image: base64Image);

      result.fold(
        (failure) {
          emit(
            currentState.copyWith(
              isUploadingImage: false,
              statusMessage: failure.message,
              isStatusError: true,
            ),
          );
        },
        (updatedProfile) {
          emit(
            ProfileLoaded(
              profile: updatedProfile,
              isUploadingImage: false,
              statusMessage: 'Profile image updated',
              isStatusError: false,
            ),
          );
        },
      );
    } catch (_) {
      emit(
        currentState.copyWith(
          isUploadingImage: false,
          statusMessage: 'Failed to process selected image',
          isStatusError: true,
        ),
      );
    }
  }

  /// Submit ID document for profile verification
  Future<void> verifyProfile(String filePath) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) {
      return;
    }

    emit(
      currentState.copyWith(
        isUploadingVerificationDocument: true,
        clearStatusMessage: true,
        isStatusError: false,
      ),
    );

    final file = File(filePath);
    if (!await file.exists()) {
      emit(
        currentState.copyWith(
          isUploadingVerificationDocument: false,
          statusMessage: 'Document file not found',
          isStatusError: true,
        ),
      );
      return;
    }

    final verifyResult = await verifyProfileUseCase(filePath: filePath);
    await verifyResult.fold(
      (failure) async {
        emit(
          currentState.copyWith(
            isUploadingVerificationDocument: false,
            statusMessage: failure.message,
            isStatusError: true,
          ),
        );
      },
      (message) async {
        final refreshedProfileResult = await getProfileUseCase();
        refreshedProfileResult.fold(
          (_) {
            emit(
              currentState.copyWith(
                isUploadingVerificationDocument: false,
                statusMessage: message,
                isStatusError: false,
              ),
            );
          },
          (profile) {
            emit(
              ProfileLoaded(
                profile: profile,
                isUploadingImage: false,
                isUploadingVerificationDocument: false,
                statusMessage: message,
                isStatusError: false,
              ),
            );
          },
        );
      },
    );
  }

  /// Clear one-time UI status message
  void clearStatusMessage() {
    final currentState = state;
    if (currentState is ProfileLoaded && currentState.statusMessage != null) {
      emit(currentState.copyWith(clearStatusMessage: true));
    }
  }

  /// Send password reset email for current profile email.
  Future<void> sendPasswordResetEmail({required String email}) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) {
      return;
    }

    emit(currentState.copyWith(clearStatusMessage: true, isStatusError: false));

    final result = await sendPasswordResetEmailUseCase(email: email);

    result.fold(
      (failure) {
        emit(
          currentState.copyWith(
            statusMessage: failure.message,
            isStatusError: true,
          ),
        );
      },
      (message) {
        emit(
          currentState.copyWith(statusMessage: message, isStatusError: false),
        );
      },
    );
  }
}
