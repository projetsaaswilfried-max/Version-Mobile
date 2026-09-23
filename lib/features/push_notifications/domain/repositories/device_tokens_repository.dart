import '../../../../core/error/result.dart';

abstract class DeviceTokensRepository {
  Future<Result<void>> registerToken({
    required String token,
    required String platform,
  });

  Future<Result<void>> deleteToken(String token);
}
