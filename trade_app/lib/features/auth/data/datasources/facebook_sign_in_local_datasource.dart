import 'dart:io';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/errors/exceptions.dart';

/// Facebook Sign-In local datasource
/// Responsible only for interacting with Facebook SDK
abstract class FacebookSignInLocalDataSource {
  Future<String> getAccessToken();
  Future<void> signOut();
}

class FacebookSignInLocalDataSourceImpl
    implements FacebookSignInLocalDataSource {
  final FacebookAuth _facebookAuth;

  FacebookSignInLocalDataSourceImpl({FacebookAuth? facebookAuth})
    : _facebookAuth = facebookAuth ?? FacebookAuth.instance;

  @override
  Future<String> getAccessToken() async {
    final result = await _facebookAuth.login(
      permissions: const ['email', 'public_profile'],
      loginBehavior: LoginBehavior.nativeWithFallback,
      loginTracking: LoginTracking.enabled,
    );

    if (result.status == LoginStatus.cancelled) {
      throw const CacheException(
        message: 'Facebook sign-in was cancelled.',
        code: 'FACEBOOK_SIGN_IN_CANCELLED',
      );
    }

    if (result.status == LoginStatus.operationInProgress) {
      throw const CacheException(
        message: 'Facebook sign-in is already in progress.',
        code: 'FACEBOOK_SIGN_IN_IN_PROGRESS',
      );
    }

    if (result.status == LoginStatus.failed) {
      throw ServerException(
        message: result.message ?? 'Facebook sign-in failed.',
        code: 'FACEBOOK_SIGN_IN_FAILED',
      );
    }
    print(result.accessToken);
    print('FBToken type: ${result.accessToken.runtimeType}');
    print('FBToken: ${result.accessToken?.tokenString?.substring(0, 30)}');

    final accessToken = result.accessToken?.tokenString;
    if (accessToken == null || accessToken.isEmpty) {
      throw const ServerException(
        message: 'Facebook sign-in did not return an access token.',
        code: 'FACEBOOK_ACCESS_TOKEN_MISSING',
      );
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/facebookToken.txt');
    await file.writeAsString(accessToken);

    print('Facebook token saved to: ${file.path}');

    return accessToken;
  }

  @override
  Future<void> signOut() async {
    try {
      await _facebookAuth.logOut();
    } catch (_) {
      // Best-effort cleanup. Local logout must still succeed.
    }
  }
}
