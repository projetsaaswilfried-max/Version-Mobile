import '../../../../core/error/result.dart';
import '../entities/my_profile.dart';
import '../repositories/my_profile_repository.dart';

class GetMyProfile {
  const GetMyProfile(this._repo);

  final MyProfileRepository _repo;

  Future<Result<MyProfile>> call() => _repo.fetchMine();
}
