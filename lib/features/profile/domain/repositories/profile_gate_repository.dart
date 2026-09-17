import '../../../../core/error/result.dart';
import '../entities/member_gate_snapshot.dart';

abstract class ProfileGateRepository {
  Future<Result<MemberGateSnapshot>> fetchGate();
}
