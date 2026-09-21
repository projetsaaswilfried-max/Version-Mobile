import '../../../../core/error/result.dart';
import '../repositories/discover_repository.dart';

class RecordDiscoverProfileView {
  const RecordDiscoverProfileView(this._repo);

  final DiscoverRepository _repo;

  Future<Result<void>> call(String viewedProfileId) =>
      _repo.recordProfileView(viewedProfileId);
}
