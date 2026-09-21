import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/feed/domain/entities/feed_filter.dart';
import 'package:agapeo/features/feed/domain/entities/feed_page.dart';
import 'package:agapeo/features/feed/domain/entities/personal_post_media.dart';
import 'package:agapeo/features/feed/domain/entities/post.dart';
import 'package:agapeo/features/feed/domain/entities/post_comment.dart';
import 'package:agapeo/features/feed/domain/repositories/feed_repository.dart';
import 'package:agapeo/features/feed/domain/usecases/record_post_share.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements FeedRepository {
  String? lastShareId;

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
  }) async => const Err(ServerFailure());

  @override
  Future<Result<void>> recordShare(String postId) async {
    lastShareId = postId;
    return const Ok(null);
  }

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
  test('RecordPostShare forwards to repository', () async {
    final repo = _FakeRepo();
    await RecordPostShare(repo)('p1');
    expect(repo.lastShareId, 'p1');
  });
}
