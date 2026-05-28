import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_app/core/network/api_endpoints.dart';

void main() {
  group('ApiEndpoints', () {
    test('uses the production Cloud Run API base URL', () {
      expect(ApiEndpoints.baseUrl, ApiEndpoints.productionBaseUrl);
      expect(
        ApiEndpoints.baseUrl,
        'https://barterx-backend-a7fym27foa-uc.a.run.app/api',
      );
    });

    test('resolves relative API paths under the /api base path', () {
      final options = RequestOptions(
        path: ApiEndpoints.login,
        baseUrl: ApiEndpoints.baseUrl,
      );

      expect(
        options.uri.toString(),
        'https://barterx-backend-a7fym27foa-uc.a.run.app/api/auth/login',
      );
    });
  });
}
