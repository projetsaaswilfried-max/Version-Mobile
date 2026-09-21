import '../../../../core/error/result.dart';
import '../entities/post.dart';
import '../repositories/feed_repository.dart';

class ListMyPosts {
  const ListMyPosts(this._repo);

  final FeedRepository _repo;

  Future<Result<List<Post>>> call() => _repo.fetchMyPosts();
}
