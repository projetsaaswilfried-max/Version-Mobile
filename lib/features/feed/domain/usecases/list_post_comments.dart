import '../../../../core/error/result.dart';
import '../entities/post_comment.dart';
import '../repositories/feed_repository.dart';

class ListPostComments {
  const ListPostComments(this._repo);

  final FeedRepository _repo;

  Future<Result<List<PostComment>>> call(String postId) {
    return _repo.fetchComments(postId);
  }
}
