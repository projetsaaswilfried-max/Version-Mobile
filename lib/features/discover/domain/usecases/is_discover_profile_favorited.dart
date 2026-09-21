import '../../../../core/error/result.dart';
import '../repositories/discover_repository.dart';

class IsDiscoverProfileFavorited {
  const IsDiscoverProfileFavorited(this._repo);

  final DiscoverRepository _repo;

  Future<Result<bool>> call(String profileId) =>
      _repo.isProfileFavorited(profileId);
}
