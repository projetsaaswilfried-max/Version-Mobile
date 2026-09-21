import '../../../../core/error/map_data_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/parsing/json.dart';
import '../../domain/entities/member_gate_snapshot.dart';
import '../../domain/entities/subscription_status.dart';
import '../../domain/repositories/profile_gate_repository.dart';
import '../datasources/profile_gate_remote_datasource.dart';

class ProfileGateRepositoryImpl implements ProfileGateRepository {
  ProfileGateRepositoryImpl(this._remote);

  final ProfileGateRemoteDataSource _remote;

  @override
  Future<Result<MemberGateSnapshot>> fetchGate() async {
    try {
      final raw = await _remote.fetchGateRaw();
      final status = Json({'subscription_status': raw.subscriptionStatus})
          .enumValue(
            'subscription_status',
            SubscriptionStatus.values,
            SubscriptionStatus.free,
          );
      return Ok(
        MemberGateSnapshot(
          isSuspended: raw.isSuspended,
          subscriptionStatus: status,
          onboardingCompleted: raw.onboardingCompleted,
        ),
      );
    } catch (error) {
      return Err(mapDataException(error));
    }
  }
}
