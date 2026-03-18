import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/device_token.dart';
import '../repositories/auth_repository.dart';

/// Register device token usecase
/// Registers FCM token with the backend for push notifications
class RegisterDeviceTokenUseCase {
  final AuthRepository repository;

  RegisterDeviceTokenUseCase(this.repository);

  Future<Either<Failure, DeviceToken>> call({
    required String token,
    required String platform,
  }) async {
    // Validate token
    if (token.isEmpty) {
      return Left(ValidationFailure(
        message: 'Device token is required',
        code: 'EMPTY_TOKEN',
      ));
    }

    // Validate platform
    if (platform.isEmpty) {
      return Left(ValidationFailure(
        message: 'Platform is required',
        code: 'EMPTY_PLATFORM',
      ));
    }

    return await repository.registerDeviceToken(
      token: token,
      platform: platform,
    );
  }
}
