import '../../../../core/error/result.dart';
import '../repositories/discover_repository.dart';

class FavoriteDiscoverProfile {
  const FavoriteDiscoverProfile(this._repo);

  final DiscoverRepository _repo;

  Future<Result<void>> call(String profileId) =>
      _repo.favoriteProfile(profileId);
}
