import '../../../../core/error/result.dart';
import '../entities/feed_filter.dart';
import '../entities/feed_page.dart';
import '../entities/personal_post_media.dart';
import '../entities/post.dart';
import '../entities/post_comment.dart';

abstract class FeedRepository {
  Future<Result<FeedPage>> fetchPage({
    required FeedFilter filter,
    required int offset,
    required int limit,
  });

  Future<Result<void>> setLiked(String postId, {required bool liked});

  Future<Result<void>> setBookmarked(String postId, {required bool bookmarked});

  Future<Result<void>> recordView(String postId);

  Future<Result<List<PostComment>>> fetchComments(String postId);

  Future<Result<PostComment>> addComment(
    String postId,
    String body, {
    String? parentId,
  });

  Future<Result<void>> recordShare(String postId);

  Future<Result<List<Post>>> fetchMyPosts();

  Future<Result<List<Post>>> fetchPersonalPostsByAuthor(String authorId);

  Future<Result<Post>> createPersonalPost({
    required String body,
    PersonalPostMedia? media,
  });

  Future<Result<Post>> updatePersonalPost({
    required String postId,
    required String body,
  });

  Future<Result<void>> deletePersonalPost(String postId);
}
