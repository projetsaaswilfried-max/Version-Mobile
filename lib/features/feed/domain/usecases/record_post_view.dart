import '../../../../core/error/result.dart';
import '../repositories/feed_repository.dart';

class RecordPostView {
  const RecordPostView(this._repo);

  final FeedRepository _repo;

  Future<Result<void>> call(String postId) => _repo.recordView(postId);
}
