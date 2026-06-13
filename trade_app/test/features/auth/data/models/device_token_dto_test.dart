import 'package:flutter_test/flutter_test.dart';
import 'package:trade_app/features/auth/data/models/device_token_dto.dart';

void main() {
  const deviceTokenJson = {
    'id': 'device-token-id',
    'token': 'fcm-token',
    'platform': 'android',
    'createdAt': '2026-06-11T10:00:00.000Z',
  };

  test('parses a root-level device token response', () {
    final response = DeviceTokenResponseModel.fromJson({
      'success': true,
      'message': 'Registered',
      'deviceToken': deviceTokenJson,
    });

    expect(response.success, isTrue);
    expect(response.deviceToken?.token, 'fcm-token');
  });

  test('parses a device token nested under data', () {
    final response = DeviceTokenResponseModel.fromJson({
      'success': true,
      'message': 'Registered',
      'data': {'deviceToken': deviceTokenJson},
    });

    expect(response.success, isTrue);
    expect(response.deviceToken?.id, 'device-token-id');
  });

  test('accepts the device token itself as the data payload', () {
    final response = DeviceTokenResponseModel.fromJson({
      'message': 'Registered',
      'data': deviceTokenJson,
    });

    expect(response.success, isTrue);
    expect(response.deviceToken?.platform, 'android');
  });
}
