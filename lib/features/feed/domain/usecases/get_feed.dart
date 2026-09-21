import '../../../../core/error/result.dart';
import '../entities/feed_filter.dart';
import '../entities/feed_page.dart';
import '../repositories/feed_repository.dart';

class GetFeed {
  const GetFeed(this._repo);

  final FeedRepository _repo;

  static const pageSize = 20;

  Future<Result<FeedPage>> call({
    required FeedFilter filter,
    required int offset,
  }) {
    return _repo.fetchPage(filter: filter, offset: offset, limit: pageSize);
  }
}
