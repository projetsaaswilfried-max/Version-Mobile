import '../../../../core/error/result.dart';
import '../repositories/discover_repository.dart';

class IsDiscoverProfileLiked {
  const IsDiscoverProfileLiked(this._repo);

  final DiscoverRepository _repo;

  Future<Result<bool>> call(String profileId) =>
      _repo.isProfileLiked(profileId);
}
