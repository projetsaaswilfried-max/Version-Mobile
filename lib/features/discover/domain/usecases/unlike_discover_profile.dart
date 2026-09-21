import '../../../../core/error/result.dart';
import '../repositories/discover_repository.dart';

class UnlikeDiscoverProfile {
  const UnlikeDiscoverProfile(this._repo);

  final DiscoverRepository _repo;

  Future<Result<void>> call(String profileId) =>
      _repo.unlikeProfile(profileId);
}
