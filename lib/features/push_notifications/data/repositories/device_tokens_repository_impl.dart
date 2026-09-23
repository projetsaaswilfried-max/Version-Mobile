import '../../../../core/error/map_data_exception.dart';
import '../../../../core/error/result.dart';
import '../../domain/repositories/device_tokens_repository.dart';
import '../datasources/supabase_device_tokens_datasource.dart';

class DeviceTokensRepositoryImpl implements DeviceTokensRepository {
  DeviceTokensRepositoryImpl(this._remote);

  final SupabaseDeviceTokensDataSource _remote;

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<void>> registerToken({
    required String token,
    required String platform,
  }) => _guard(
    () => _remote.registerToken(token: token, platform: platform),
  );

  @override
  Future<Result<void>> deleteToken(String token) =>
      _guard(() => _remote.deleteToken(token));
}
