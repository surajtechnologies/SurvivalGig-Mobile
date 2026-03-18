import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../../../../config/env/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Google Sign-In local datasource
/// Responsible only for interacting with Google Sign-In SDK
abstract class GoogleSignInLocalDataSource {
  Future<String> getIdToken();
  Future<void> signOut();
}

class GoogleSignInLocalDataSourceImpl implements GoogleSignInLocalDataSource {
  final GoogleSignIn _googleSignIn;
  bool _isInitialized = false;

  GoogleSignInLocalDataSourceImpl({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  String? _platformClientId() {
    if (kIsWeb) return null;

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return AppConfig.googleIosClientId.isNotEmpty
            ? AppConfig.googleIosClientId
            : null;
      case TargetPlatform.android:
        return AppConfig.googleAndroidClientId.isNotEmpty
            ? AppConfig.googleAndroidClientId
            : null;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return null;
    }
  }

  Future<void> _initializeIfRequired() async {
    if (_isInitialized) return;

    await _googleSignIn.initialize(
      clientId: _platformClientId(),
      serverClientId: AppConfig.googleServerClientId.isNotEmpty
          ? AppConfig.googleServerClientId
          : null,
    );

    _isInitialized = true;
  }

  @override
  Future<String> getIdToken() async {
    try {
      await _initializeIfRequired();

      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/token.txt');

      await file.writeAsString(idToken!);

      print("Token saved to: ${file.path}");

      // File('token.txt').writeAsStringSync(idToken!);
      if (idToken == null || idToken.isEmpty) {
        throw const ServerException(
          message: 'Google sign-in did not return an ID token.',
          code: 'GOOGLE_ID_TOKEN_MISSING',
        );
      }

      return idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const CacheException(
          message: 'Google sign-in was cancelled.',
          code: 'GOOGLE_SIGN_IN_CANCELLED',
        );
      }

      if (e.code == GoogleSignInExceptionCode.clientConfigurationError) {
        throw const CacheException(
          message: 'Google sign-in is not configured for this app.',
          code: 'GOOGLE_CLIENT_CONFIG_ERROR',
        );
      }

      throw ServerException(
        message: e.description ?? 'Google sign-in failed.',
        code: e.code.name,
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _initializeIfRequired();
      await _googleSignIn.signOut();
    } on GoogleSignInException {
      // Best-effort cleanup. Local logout must still succeed.
    }
  }
}
