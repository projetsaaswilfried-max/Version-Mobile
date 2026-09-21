import '../../../../core/error/result.dart';
import '../entities/post.dart';
import '../repositories/feed_repository.dart';

class ListPersonalPosts {
  const ListPersonalPosts(this._repo);

  final FeedRepository _repo;

  Future<Result<List<Post>>> call(String authorId) {
    final id = authorId.trim();
    if (id.isEmpty) return Future.value(const Ok([]));
    return _repo.fetchPersonalPostsByAuthor(id);
  }
}
