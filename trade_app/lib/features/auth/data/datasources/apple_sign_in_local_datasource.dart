import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../../core/errors/exceptions.dart';

/// Apple Sign-In local datasource
/// Responsible only for interacting with Apple Sign-In SDK
abstract class AppleSignInLocalDataSource {
  Future<({String identityToken, String authorizationCode, String? email, String? firstName, String? lastName})> getCredentials();
}

class AppleSignInLocalDataSourceImpl implements AppleSignInLocalDataSource {
  @override
  Future<({String identityToken, String authorizationCode, String? email, String? firstName, String? lastName})>
      getCredentials() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      final authorizationCode = credential.authorizationCode;

      if (identityToken == null || identityToken.isEmpty) {
        throw const ServerException(
          message: 'Apple sign-in did not return an identity token.',
          code: 'APPLE_IDENTITY_TOKEN_MISSING',
        );
      }

      if (authorizationCode.isEmpty) {
        throw const ServerException(
          message: 'Apple sign-in did not return an authorization code.',
          code: 'APPLE_AUTH_CODE_MISSING',
        );
      }

      return (
        identityToken: identityToken,
        authorizationCode: authorizationCode,
        email: credential.email,
        firstName: credential.givenName,
        lastName: credential.familyName,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const CacheException(
          message: 'Apple sign-in was cancelled.',
          code: 'APPLE_SIGN_IN_CANCELLED',
        );
      }

      throw ServerException(
        message: e.message,
        code: 'APPLE_SIGN_IN_FAILED',
      );
    }
  }
}

