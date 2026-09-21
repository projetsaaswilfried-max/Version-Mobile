import '../../../../core/error/map_data_exception.dart';
import '../../../../core/error/result.dart';
import '../../domain/report_reason.dart';
import '../../domain/repositories/safety_repository.dart';
import '../datasources/supabase_safety_datasource.dart';

class SafetyRepositoryImpl implements SafetyRepository {
  SafetyRepositoryImpl(this._remote);

  final SupabaseSafetyDataSource _remote;

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<void>> report({
    required ReportTargetType targetType,
    required String targetId,
    required ReportReason reason,
    String details = '',
  }) => _guard(
    () => _remote.report(
      targetType: targetType,
      targetId: targetId,
      reason: reason,
      details: details,
    ),
  );

  @override
  Future<Result<void>> block(String profileId) =>
      _guard(() => _remote.block(profileId));
}
