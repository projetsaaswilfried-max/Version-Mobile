import '../../../../core/error/result.dart';
import '../repositories/feed_repository.dart';

class DeletePersonalPost {
  const DeletePersonalPost(this._repo);

  final FeedRepository _repo;

  Future<Result<void>> call(String postId) => _repo.deletePersonalPost(postId);
}
