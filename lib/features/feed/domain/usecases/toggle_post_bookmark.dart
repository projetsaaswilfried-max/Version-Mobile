import '../../../../core/error/result.dart';
import '../repositories/feed_repository.dart';

class TogglePostBookmark {
  const TogglePostBookmark(this._repo);

  final FeedRepository _repo;

  Future<Result<void>> call(String postId, {required bool bookmarked}) {
    return _repo.setBookmarked(postId, bookmarked: bookmarked);
  }
}
