import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/feed/domain/entities/feed_filter.dart';
import 'package:agapeo/features/feed/domain/entities/feed_page.dart';
import 'package:agapeo/features/feed/domain/entities/personal_post_media.dart';
import 'package:agapeo/features/feed/domain/entities/post.dart';
import 'package:agapeo/features/feed/domain/entities/post_author.dart';
import 'package:agapeo/features/feed/domain/entities/post_comment.dart';
import 'package:agapeo/features/feed/domain/entities/post_media_type.dart';
import 'package:agapeo/features/feed/domain/repositories/feed_repository.dart';
import 'package:agapeo/features/feed/domain/usecases/get_feed.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFeedRepository implements FeedRepository {
  FeedFilter? lastFilter;
  int? lastOffset;
  int? lastLimit;
  Result<FeedPage> result = const Ok(FeedPage(items: [], hasMore: false));

  @override
  Future<Result<FeedPage>> fetchPage({
    required FeedFilter filter,
    required int offset,
    required int limit,
  }) async {
    lastFilter = filter;
    lastOffset = offset;
    lastLimit = limit;
    return result;
  }

  @override
  Future<Result<void>> setLiked(String postId, {required bool liked}) async =>
      const Ok(null);

  @override
  Future<Result<void>> setBookmarked(
    String postId, {
    required bool bookmarked,
  }) async => const Ok(null);

  @override
  Future<Result<void>> recordView(String postId) async => const Ok(null);

  @override
  Future<Result<List<PostComment>>> fetchComments(String postId) async =>
      const Ok([]);

  @override
  Future<Result<PostComment>> addComment(
    String postId,
    String body, {
    String? parentId,
  }) async => const Err(ServerFailure());

  @override
  Future<Result<void>> recordShare(String postId) async => const Ok(null);

  @override
  Future<Result<List<Post>>> fetchMyPosts() async => const Ok([]);

  @override
  Future<Result<List<Post>>> fetchPersonalPostsByAuthor(String authorId) async =>
      const Ok([]);


  @override
  Future<Result<Post>> createPersonalPost({
    required String body,
    PersonalPostMedia? media,
  }) async => const Err(ServerFailure());

  @override
  Future<Result<Post>> updatePersonalPost({
    required String postId,
    required String body,
  }) async => const Err(ServerFailure());

  @override
  Future<Result<void>> deletePersonalPost(String postId) async =>
      const Ok(null);
}

Post _post(String id) {
  return Post(
    id: id,
    author: const PostAuthor(displayName: 'Agapeo'),
    body: 'Hello',
    mediaType: PostMediaType.textOnly,
    isPinned: false,
    likeCount: 0,
    commentCount: 0,
    shareCount: 0,
  );
}

void main() {
  test('GetFeed always requests page size 20', () async {
    final repo = _FakeFeedRepository();
    final getFeed = GetFeed(repo);

    await getFeed(filter: const FeedFilter.all(), offset: 40);

    expect(repo.lastFilter, const FeedFilter.all());
    expect(repo.lastOffset, 40);
    expect(repo.lastLimit, GetFeed.pageSize);
    expect(GetFeed.pageSize, 20);
  });

  test('GetFeed forwards Ok page', () async {
    final repo = _FakeFeedRepository()
      ..result = Ok(FeedPage(items: [_post('1'), _post('2')], hasMore: true));
    final page = await GetFeed(repo)(filter: const FeedFilter.all(), offset: 0);
    expect(page, isA<Ok<FeedPage>>());
    final ok = page as Ok<FeedPage>;
    expect(ok.value.items.length, 2);
    expect(ok.value.hasMore, isTrue);
  });

  test('GetFeed forwards Err', () async {
    final repo = _FakeFeedRepository()..result = const Err(NetworkFailure());
    final page = await GetFeed(repo)(filter: const FeedFilter.all(), offset: 0);
    expect(page, isA<Err<FeedPage>>());
    expect((page as Err).failure, isA<NetworkFailure>());
  });
}
