import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/fcm_notifications.dart';
import '../../domain/usecases/apple_sign_in_usecase.dart';
import '../../domain/usecases/facebook_sign_in_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/google_sign_in_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/upload_profile_image_usecase.dart';
import 'auth_state.dart';

/// Auth cubit for managing authentication state
class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final AppleSignInUseCase appleSignInUseCase;
  final FacebookSignInUseCase facebookSignInUseCase;
  final GoogleSignInUseCase googleSignInUseCase;
  final RegisterUseCase registerUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final UploadProfileImageUseCase uploadProfileImageUseCase;
  final PushNotificationService pushNotificationService;

  AuthCubit({
    required this.loginUseCase,
    required this.appleSignInUseCase,
    required this.facebookSignInUseCase,
    required this.googleSignInUseCase,
    required this.registerUseCase,
    required this.forgotPasswordUseCase,
    required this.uploadProfileImageUseCase,
    required this.pushNotificationService,
  }) : super(const AuthInitial());

  /// Login with email and password
  Future<void> login({required String email, required String password}) async {
    emit(const AuthLoading());

    final result = await loginUseCase(email: email, password: password);

    await result.fold<Future<void>>(
      (failure) async =>
          emit(AuthFailure(message: failure.message, code: failure.code)),
      (data) async => _emitLoginSuccessAfterDeviceToken(
        userId: data.user.id,
        userName: data.user.name,
      ),
    );
  }

  /// Login with Google OAuth
  Future<void> signInWithGoogle() async {
    emit(const AuthLoading());

    final result = await googleSignInUseCase();

    await result.fold<Future<void>>(
      (failure) async {
        if (failure.code == 'GOOGLE_SIGN_IN_CANCELLED') {
          emit(const AuthInitial());
          return;
        }
        emit(AuthFailure(message: failure.message, code: failure.code));
      },
      (data) async => _emitLoginSuccessAfterDeviceToken(
        userId: data.user.id,
        userName: data.user.name,
      ),
    );
  }

  /// Login with Facebook OAuth
  Future<void> signInWithFacebook() async {
    emit(const AuthLoading());

    final result = await facebookSignInUseCase();

    await result.fold<Future<void>>(
      (failure) async {
        if (failure.code == 'FACEBOOK_SIGN_IN_CANCELLED') {
          emit(const AuthInitial());
          return;
        }
        emit(AuthFailure(message: failure.message, code: failure.code));
      },
      (data) async => _emitLoginSuccessAfterDeviceToken(
        userId: data.user.id,
        userName: data.user.name,
      ),
    );
  }

  /// Login with Apple OAuth
  Future<void> signInWithApple() async {
    emit(const AuthLoading());

    final result = await appleSignInUseCase();

    await result.fold<Future<void>>(
      (failure) {
        if (failure.code == 'APPLE_SIGN_IN_CANCELLED') {
          emit(const AuthInitial());
          return Future<void>.value();
        }
        emit(AuthFailure(message: failure.message, code: failure.code));
        return Future<void>.value();
      },
      (data) => _emitLoginSuccessAfterDeviceToken(
        userId: data.user.id,
        userName: data.user.name,
      ),
    );
  }

  Future<void> _emitLoginSuccessAfterDeviceToken({
    required String userId,
    required String userName,
  }) async {
    emit(LoginSuccess(userId: userId, userName: userName));
    unawaited(pushNotificationService.syncTokenForAuthenticatedUser());
  }

  /// Upload profile image independently
  Future<void> uploadImage(String base64Image) async {
    emit(const AuthLoading());

    final result = await uploadProfileImageUseCase(base64Image: base64Image);

    result.fold(
      (failure) =>
          emit(AuthFailure(message: failure.message, code: failure.code)),
      (url) => emit(ProfileImageUploadSuccess(imageUrl: url)),
    );
  }

  /// Register new user
  Future<void> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? location,
    String? profileImageUrl, // Changed from base64Image to profileImageUrl
  }) async {
    emit(const AuthLoading());

    // Profile image logic moved to uploadImage method as per new requirement.
    // Here we expect the URL to be passed directly if an image was uploaded.

    final result = await registerUseCase(
      email: email,
      password: password,
      name: name,
      phone: phone,
      location: location,
      profileImage: profileImageUrl,
    );

    result.fold(
      (failure) =>
          emit(AuthFailure(message: failure.message, code: failure.code)),
      (data) => emit(
        RegisterSuccess(
          userId: data.user.id,
          userName: data.user.name,
          message: data.message,
        ),
      ),
    );
  }

  /// Request password reset
  Future<void> forgotPassword({required String email}) async {
    emit(const AuthLoading());

    final result = await forgotPasswordUseCase(email: email);

    result.fold(
      (failure) =>
          emit(AuthFailure(message: failure.message, code: failure.code)),
      (message) => emit(ForgotPasswordSuccess(message: message)),
    );
  }

  /// Reset to initial state
  void reset() {
    emit(const AuthInitial());
  }
}
