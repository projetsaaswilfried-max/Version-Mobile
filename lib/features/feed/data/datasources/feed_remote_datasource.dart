import '../../domain/entities/feed_filter.dart';

abstract class FeedRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchPosts({
    required FeedFilter filter,
    required int offset,
    required int limit,
  });

  Future<Set<String>> fetchLikedPostIds(List<String> postIds);

  Future<Set<String>> fetchBookmarkedPostIds(List<String> postIds);

  Future<void> setPostLiked(String postId, {required bool liked});

  Future<void> setPostBookmarked(String postId, {required bool bookmarked});

  Future<void> recordPostView(String postId);

  Future<List<Map<String, dynamic>>> fetchComments(String postId);

  Future<Map<String, dynamic>> insertComment(
    String postId,
    String body, {
    String? parentId,
  });

  Future<void> recordPostShare(String postId);

  Future<List<Map<String, dynamic>>> fetchMyPosts();

  Future<List<Map<String, dynamic>>> fetchPersonalPostsByAuthor(
    String authorId,
  );

  Future<Map<String, dynamic>> insertPersonalPost({
    required String body,
    required String mediaType,
  });

  Future<void> attachPersonalMedia({
    required String postId,
    required String localPath,
    required bool isVideo,
  });

  Future<Map<String, dynamic>> updatePersonalPost({
    required String postId,
    required String body,
  });

  Future<void> deletePersonalPost(String postId);
}
