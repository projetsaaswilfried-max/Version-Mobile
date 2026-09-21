import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/feed/domain/entities/feed_filter.dart';
import 'package:agapeo/features/feed/domain/entities/feed_page.dart';
import 'package:agapeo/features/feed/domain/entities/personal_post_media.dart';
import 'package:agapeo/features/feed/domain/entities/post.dart';
import 'package:agapeo/features/feed/domain/entities/post_comment.dart';
import 'package:agapeo/features/feed/domain/repositories/feed_repository.dart';
import 'package:agapeo/features/feed/domain/usecases/add_post_comment.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements FeedRepository {
  String? lastPostId;
  String? lastBody;
  String? lastParentId;

  @override
  Future<Result<FeedPage>> fetchPage({
    required FeedFilter filter,
    required int offset,
    required int limit,
  }) async => const Ok(FeedPage(items: [], hasMore: false));

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
  }) async {
    lastPostId = postId;
    lastBody = body;
    lastParentId = parentId;
    return Ok(PostComment(id: 'c1', body: body, authorName: 'Moi'));
  }

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

void main() {
  test('trims body before insert', () async {
    final repo = _FakeRepo();
    final result = await AddPostComment(repo)('p1', '  Amen  ');
    expect(repo.lastPostId, 'p1');
    expect(repo.lastBody, 'Amen');
    expect((result as Ok<PostComment>).value.body, 'Amen');
  });

  test('rejects empty body without calling repo', () async {
    final repo = _FakeRepo();
    final result = await AddPostComment(repo)('p1', '   ');
    expect(result, isA<Err<PostComment>>());
    expect((result as Err<PostComment>).failure, isA<ValidationFailure>());
    expect(repo.lastPostId, isNull);
    expect(repo.lastParentId, isNull);
  });

  test('forwards parentId for a reply', () async {
    final repo = _FakeRepo();
    await AddPostComment(repo)('p1', 'Oui', parentId: 'c1');
    expect(repo.lastParentId, 'c1');
  });
}
