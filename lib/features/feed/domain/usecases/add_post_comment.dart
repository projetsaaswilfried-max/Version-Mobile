import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/post_comment.dart';
import '../repositories/feed_repository.dart';

class AddPostComment {
  const AddPostComment(this._repo);

  final FeedRepository _repo;

  Future<Result<PostComment>> call(
    String postId,
    String body, {
    String? parentId,
  }) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        const Err(ValidationFailure('Écris un commentaire.')),
      );
    }
    return _repo.addComment(postId, trimmed, parentId: parentId);
  }
}
