import '../../../../core/error/result.dart';
import '../repositories/feed_repository.dart';

class RecordPostShare {
  const RecordPostShare(this._repo);

  final FeedRepository _repo;

  Future<Result<void>> call(String postId) => _repo.recordShare(postId);
}
