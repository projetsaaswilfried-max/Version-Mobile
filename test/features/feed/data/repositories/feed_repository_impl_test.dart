import 'package:agapeo/core/error/exceptions.dart';
import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/feed/data/datasources/feed_remote_datasource.dart';
import 'package:agapeo/features/feed/data/repositories/feed_repository_impl.dart';
import 'package:agapeo/features/feed/domain/entities/feed_filter.dart';
import 'package:agapeo/features/feed/domain/entities/feed_page.dart';
import 'package:agapeo/features/feed/domain/entities/personal_post_media.dart';
import 'package:agapeo/features/feed/domain/entities/post.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRemote implements FeedRemoteDataSource {
  _FakeRemote(this.rows);
  List<Map<String, dynamic>> rows;
  Object? throwError;
  FeedFilter? lastFilter;
  int? lastOffset;
  int? lastLimit;
  Set<String> likedIds = {};
  Set<String> bookmarkedIds = {};
  Object? attachMediaError;
  final attachMediaCalls = <String>[];

  @override
  Future<List<Map<String, dynamic>>> fetchPosts({
    required FeedFilter filter,
    required int offset,
    required int limit,
  }) async {
    lastFilter = filter;
    lastOffset = offset;
    lastLimit = limit;
    if (throwError != null) throw throwError!;
    return rows;
  }

  @override
  Future<Set<String>> fetchLikedPostIds(List<String> postIds) async => likedIds;

  @override
  Future<Set<String>> fetchBookmarkedPostIds(List<String> postIds) async =>
      bookmarkedIds;

  @override
  Future<void> setPostLiked(String postId, {required bool liked}) async {}

  @override
  Future<void> setPostBookmarked(
    String postId, {
    required bool bookmarked,
  }) async {}

  @override
  Future<void> recordPostView(String postId) async {}

  @override
  Future<List<Map<String, dynamic>>> fetchComments(String postId) async => [];

  @override
  Future<Map<String, dynamic>> insertComment(
    String postId,
    String body, {
    String? parentId,
  }) async => {'id': 'c', 'content': body};

  @override
  Future<void> recordPostShare(String postId) async {}

  @override
  Future<List<Map<String, dynamic>>> fetchMyPosts() async => [];

  @override
  Future<List<Map<String, dynamic>>> fetchPersonalPostsByAuthor(
    String authorId,
  ) async => [];


  @override
  Future<Map<String, dynamic>> insertPersonalPost({
    required String body,
    required String mediaType,
  }) async => {'id': 'n', 'post_type': 'PERSONAL', 'content': body};

  @override
  Future<void> attachPersonalMedia({
    required String postId,
    required String localPath,
    required bool isVideo,
  }) async {
    attachMediaCalls.add(postId);
    if (attachMediaError != null) throw attachMediaError!;
  }

  @override
  Future<Map<String, dynamic>> updatePersonalPost({
    required String postId,
    required String body,
  }) async => {'id': postId, 'post_type': 'PERSONAL', 'content': body};

  @override
  Future<void> deletePersonalPost(String postId) async {}
}

Map<String, dynamic> _official(String id) => {
  'id': id,
  'post_type': 'OFFICIAL',
  'content': 'x',
};

void main() {
  test('maps rows to page and hasMore when length equals limit', () async {
    final remote = _FakeRemote([
      _official('1'),
      _official('2'),
      {'id': 'skip', 'post_type': 'PERSONAL', 'content': 'no'},
    ]);
    final repo = FeedRepositoryImpl(remote);
    final result = await repo.fetchPage(
      filter: const FeedFilter.all(),
      offset: 0,
      limit: 3,
    );
    expect(result, isA<Ok<FeedPage>>());
    final page = (result as Ok<FeedPage>).value;
    expect(page.items.map((p) => p.id).toList(), ['1', '2']);
    expect(page.hasMore, isTrue);
  });

  test('hydrates likedByMe from engagement ids', () async {
    final remote = _FakeRemote([_official('1'), _official('2')])
      ..likedIds = {'2'};
    final page =
        (await FeedRepositoryImpl(remote).fetchPage(
                  filter: const FeedFilter.all(),
                  offset: 0,
                  limit: 20,
                )
                as Ok<FeedPage>)
            .value;
    expect(page.items[0].likedByMe, isFalse);
    expect(page.items[1].likedByMe, isTrue);
  });

  test('hasMore is false when fewer rows than limit', () async {
    final remote = _FakeRemote([_official('1')]);
    final result = await FeedRepositoryImpl(
      remote,
    ).fetchPage(filter: const FeedFilter.all(), offset: 0, limit: 20);
    expect((result as Ok<FeedPage>).value.hasMore, isFalse);
  });

  test('maps NetworkException to NetworkFailure', () async {
    final remote = _FakeRemote([])..throwError = const NetworkException();
    final result = await FeedRepositoryImpl(
      remote,
    ).fetchPage(filter: const FeedFilter.all(), offset: 0, limit: 20);
    expect(result, isA<Err<FeedPage>>());
    expect((result as Err).failure, isA<NetworkFailure>());
  });

  test('maps ServerException to ServerFailure', () async {
    final remote = _FakeRemote([])..throwError = const ServerException('boom');
    final result = await FeedRepositoryImpl(
      remote,
    ).fetchPage(filter: const FeedFilter.all(), offset: 0, limit: 20);
    expect((result as Err).failure, isA<ServerFailure>());
  });

  test(
    'createPersonalPost attaches the media for the created post id',
    () async {
      final remote = _FakeRemote([]);
      final result = await FeedRepositoryImpl(remote).createPersonalPost(
        body: 'Un enseignement',
        media: const PersonalPostMedia(
          localPath: '/tmp/photo.jpg',
          byteSize: 100,
          isVideo: false,
        ),
      );
      expect(result, isA<Ok<Post>>());
      expect(remote.attachMediaCalls, ['n']);
    },
  );

  test(
    'createPersonalPost surfaces a media attach failure instead of a false Ok '
    '(post_media insert used to fail silently on a nonexistent column)',
    () async {
      final remote = _FakeRemote([])
        ..attachMediaError = const ServerException('column does not exist');
      final result = await FeedRepositoryImpl(remote).createPersonalPost(
        body: 'Un enseignement',
        media: const PersonalPostMedia(
          localPath: '/tmp/photo.jpg',
          byteSize: 100,
          isVideo: false,
        ),
      );
      expect(result, isA<Err<Post>>());
    },
  );
}
