import '../../../../core/error/result.dart';
import '../report_reason.dart';

abstract class SafetyRepository {
  Future<Result<void>> report({
    required ReportTargetType targetType,
    required String targetId,
    required ReportReason reason,
    String details,
  });

  Future<Result<void>> block(String profileId);
}
