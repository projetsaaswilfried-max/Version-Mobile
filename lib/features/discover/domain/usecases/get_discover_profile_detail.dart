import '../../../../core/error/result.dart';
import '../entities/discover_profile_detail.dart';
import '../repositories/discover_repository.dart';

class GetDiscoverProfileDetail {
  const GetDiscoverProfileDetail(this._repo);

  final DiscoverRepository _repo;

  Future<Result<DiscoverProfileDetail>> call(String id) =>
      _repo.fetchProfileDetail(id);
}
