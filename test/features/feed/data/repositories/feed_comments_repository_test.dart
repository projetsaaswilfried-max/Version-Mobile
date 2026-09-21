import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/feed/data/datasources/feed_remote_datasource.dart';
import 'package:agapeo/features/feed/data/repositories/feed_repository_impl.dart';
import 'package:agapeo/features/feed/domain/entities/feed_filter.dart';
import 'package:agapeo/features/feed/domain/entities/post_comment.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRemote implements FeedRemoteDataSource {
  List<Map<String, dynamic>> commentRows = [];
  Map<String, dynamic>? inserted;
  String? lastPostId;
  String? lastBody;
  String? lastParentId;

  @override
  Future<List<Map<String, dynamic>>> fetchPosts({
    required FeedFilter filter,
    required int offset,
    required int limit,
  }) async => [];

  @override
  Future<Set<String>> fetchLikedPostIds(List<String> postIds) async => {};

  @override
  Future<Set<String>> fetchBookmarkedPostIds(List<String> postIds) async => {};

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
  Future<List<Map<String, dynamic>>> fetchComments(String postId) async {
    lastPostId = postId;
    return commentRows;
  }

  @override
  Future<Map<String, dynamic>> insertComment(
    String postId,
    String body, {
    String? parentId,
  }) async {
    lastPostId = postId;
    lastBody = body;
    lastParentId = parentId;
    return inserted ?? {'id': 'c9', 'content': body};
  }

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
  }) async {}

  @override
  Future<Map<String, dynamic>> updatePersonalPost({
    required String postId,
    required String body,
  }) async => {'id': postId, 'post_type': 'PERSONAL', 'content': body};

  @override
  Future<void> deletePersonalPost(String postId) async {}
}

void main() {
  test('fetchComments maps rows and skips invalid', () async {
    final remote = _FakeRemote()
      ..commentRows = [
        {
          'id': 'c1',
          'content': 'Amen',
          'author': {'first_name': 'Léa'},
        },
        {'content': 'no-id'},
      ];
    final result = await FeedRepositoryImpl(remote).fetchComments('p1');
    expect(remote.lastPostId, 'p1');
    final items = (result as Ok<List<PostComment>>).value;
    expect(items, hasLength(1));
    expect(items.single.body, 'Amen');
    expect(items.single.authorName, 'Léa');
  });

  test('addComment maps insert row', () async {
    final remote = _FakeRemote();
    final result = await FeedRepositoryImpl(remote).addComment('p1', 'Merci');
    expect(remote.lastBody, 'Merci');
    final mapped = (result as Ok<PostComment>).value;
    expect(mapped.body, 'Merci');
    expect(mapped.id, 'c9');
  });

  test('addComment fallback keeps a unique id and parentId', () async {
    final remote = _FakeRemote()..inserted = {'content': 'Merci'};
    final result = await FeedRepositoryImpl(
      remote,
    ).addComment('p1', 'Merci', parentId: 'c1');
    final comment = (result as Ok<PostComment>).value;
    expect(comment.body, 'Merci');
    expect(comment.parentId, 'c1');
    expect(comment.id, isNot('p1'));
    expect(remote.lastParentId, 'c1');
  });
}
