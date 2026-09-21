import '../../../../core/error/result.dart';
import '../repositories/discover_repository.dart';

class UnfavoriteDiscoverProfile {
  const UnfavoriteDiscoverProfile(this._repo);

  final DiscoverRepository _repo;

  Future<Result<void>> call(String profileId) =>
      _repo.unfavoriteProfile(profileId);
}
