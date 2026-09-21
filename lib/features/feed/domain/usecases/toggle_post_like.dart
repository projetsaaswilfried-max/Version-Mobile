import '../../../../core/error/result.dart';
import '../repositories/feed_repository.dart';

class TogglePostLike {
  const TogglePostLike(this._repo);

  final FeedRepository _repo;

  Future<Result<void>> call(String postId, {required bool liked}) {
    return _repo.setLiked(postId, liked: liked);
  }
}
