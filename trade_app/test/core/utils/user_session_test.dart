import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:trade_app/core/utils/user_session.dart';

void main() {
  group('UserSession.isJwtExpired', () {
    test('returns true when exp is in the past', () {
      final token = _jwtWithExp(
        DateTime.utc(2026).millisecondsSinceEpoch ~/ 1000,
      );

      expect(
        UserSession.isJwtExpired(token, now: DateTime.utc(2026, 1, 1, 0, 0, 1)),
        isTrue,
      );
    });

    test('returns false when exp is in the future', () {
      final token = _jwtWithExp(
        DateTime.utc(2026, 1, 1, 0, 0, 2).millisecondsSinceEpoch ~/ 1000,
      );

      expect(
        UserSession.isJwtExpired(token, now: DateTime.utc(2026, 1, 1)),
        isFalse,
      );
    });

    test('returns false for malformed tokens', () {
      expect(UserSession.isJwtExpired('not-a-jwt'), isFalse);
    });
  });
}

String _jwtWithExp(int expirySeconds) {
  final header = _base64UrlJson({'alg': 'none', 'typ': 'JWT'});
  final payload = _base64UrlJson({'exp': expirySeconds});
  return '$header.$payload.signature';
}

String _base64UrlJson(Map<String, Object?> value) {
  return base64UrlEncode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
}
