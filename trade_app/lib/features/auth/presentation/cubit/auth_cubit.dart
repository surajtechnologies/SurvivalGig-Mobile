import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/apple_sign_in_usecase.dart';
import '../../domain/usecases/facebook_sign_in_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/google_sign_in_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/register_device_token_usecase.dart';
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
  final RegisterDeviceTokenUseCase registerDeviceTokenUseCase;

  AuthCubit({
    required this.loginUseCase,
    required this.appleSignInUseCase,
    required this.facebookSignInUseCase,
    required this.googleSignInUseCase,
    required this.registerUseCase,
    required this.forgotPasswordUseCase,
    required this.uploadProfileImageUseCase,
    required this.registerDeviceTokenUseCase,
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

    result.fold(
      (failure) {
        if (failure.code == 'APPLE_SIGN_IN_CANCELLED') {
          emit(const AuthInitial());
          return;
        }
        emit(AuthFailure(message: failure.message, code: failure.code));
      },
      (data) =>
          emit(LoginSuccess(userId: data.user.id, userName: data.user.name)),
    );
  }

  Future<void> _emitLoginSuccessAfterDeviceToken({
    required String userId,
    required String userName,
  }) async {
    await _registerDeviceTokenForCurrentPlatform();
    emit(LoginSuccess(userId: userId, userName: userName));
  }

  Future<void> _registerDeviceTokenForCurrentPlatform() async {
    try {
      if (!Platform.isAndroid && !Platform.isIOS) return;

      final messaging = FirebaseMessaging.instance;
      if (Platform.isIOS) {
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        final isAuthorized =
            settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
        if (!isAuthorized) return;
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } else {
        await messaging.requestPermission();
      }

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;

      final platform = Platform.isIOS ? 'ios' : 'android';
      await registerDeviceTokenUseCase(token: token, platform: platform);
    } catch (_) {
      // Device token registration should not block a successful login.
    }
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

  /// Register FCM device token for push notifications
  /// This is a fire-and-forget operation that does NOT emit loading state
  /// to avoid interfering with login/navigation flow
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    final result = await registerDeviceTokenUseCase(
      token: token,
      platform: platform,
    );

    result.fold(
      (failure) {
        // Silent failure - device token registration should not block user
      },
      (deviceToken) {
        // Token registered successfully - no state emission needed
      },
    );
  }

  /// Reset to initial state
  void reset() {
    emit(const AuthInitial());
  }
}
