import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/feed/domain/entities/feed_filter.dart';
import 'package:agapeo/features/feed/domain/entities/feed_page.dart';
import 'package:agapeo/features/feed/domain/entities/personal_post_media.dart';
import 'package:agapeo/features/feed/domain/entities/post.dart';
import 'package:agapeo/features/feed/domain/entities/post_author.dart';
import 'package:agapeo/features/feed/domain/entities/post_category.dart';
import 'package:agapeo/features/feed/domain/entities/post_comment.dart';
import 'package:agapeo/features/feed/domain/entities/post_media_type.dart';
import 'package:agapeo/features/feed/domain/repositories/feed_repository.dart';

class FakeFeedRepository implements FeedRepository {
  FakeFeedRepository({Result<FeedPage>? result})
    : result = result ?? const Ok(FeedPage(items: [], hasMore: false));

  Result<FeedPage> result;
  final calls = <({FeedFilter filter, int offset, int limit})>[];
  final liked = <String, bool>{};
  final bookmarked = <String, bool>{};
  final viewed = <String>[];
  final commentsByPost = <String, List<PostComment>>{};
  final addedBodies = <String>[];
  final shared = <String>[];
  List<Post> myPosts = const [];

  @override
  Future<Result<FeedPage>> fetchPage({
    required FeedFilter filter,
    required int offset,
    required int limit,
  }) async {
    calls.add((filter: filter, offset: offset, limit: limit));
    return result;
  }

  @override
  Future<Result<void>> setLiked(String postId, {required bool liked}) async {
    this.liked[postId] = liked;
    return const Ok(null);
  }

  @override
  Future<Result<void>> setBookmarked(
    String postId, {
    required bool bookmarked,
  }) async {
    this.bookmarked[postId] = bookmarked;
    return const Ok(null);
  }

  @override
  Future<Result<void>> recordView(String postId) async {
    viewed.add(postId);
    return const Ok(null);
  }

  @override
  Future<Result<List<PostComment>>> fetchComments(String postId) async {
    return Ok(commentsByPost[postId] ?? const []);
  }

  @override
  Future<Result<PostComment>> addComment(
    String postId,
    String body, {
    String? parentId,
  }) async {
    addedBodies.add(body);
    final comment = PostComment(
      id: 'new-${addedBodies.length}',
      body: body,
      authorName: 'Moi',
      parentId: parentId,
    );
    commentsByPost.update(
      postId,
      (existing) => [...existing, comment],
      ifAbsent: () => [comment],
    );
    return Ok(comment);
  }

  @override
  Future<Result<void>> recordShare(String postId) async {
    shared.add(postId);
    return const Ok(null);
  }

  @override
  Future<Result<List<Post>>> fetchMyPosts() async => Ok(myPosts);

  @override
  Future<Result<List<Post>>> fetchPersonalPostsByAuthor(String authorId) async =>
      Ok(myPosts);

  @override
  Future<Result<Post>> createPersonalPost({
    required String body,
    PersonalPostMedia? media,
  }) async {
    final post = fakePost(id: 'created', body: body);
    myPosts = [...myPosts, post];
    return Ok(post);
  }

  @override
  Future<Result<Post>> updatePersonalPost({
    required String postId,
    required String body,
  }) async {
    return Ok(fakePost(id: postId, body: body));
  }

  @override
  Future<Result<void>> deletePersonalPost(String postId) async {
    myPosts = [
      for (final post in myPosts)
        if (post.id != postId) post,
    ];
    return const Ok(null);
  }
}

Post fakePost({
  String id = '1',
  String? title,
  String body = 'Un enseignement',
  PostMediaType mediaType = PostMediaType.textOnly,
  String? quoteAttribution,
  bool pinned = false,
  PostAuthor author = const PostAuthor(
    displayName: 'Équipe Agapeo',
    isVerified: true,
  ),
  PostCategory? category,
  DateTime? createdAt,
  String? thumbnailUrl,
  String? youtubeUrl,
  String? imageUrl,
  List<String> mediaUrls = const [],
  int viewCount = 0,
}) {
  return Post(
    id: id,
    author: author,
    category: category,
    title: title,
    body: body,
    mediaType: mediaType,
    imageUrl: imageUrl,
    thumbnailUrl: thumbnailUrl,
    mediaUrls: mediaUrls,
    quoteAttribution: quoteAttribution,
    youtubeUrl: youtubeUrl,
    isPinned: pinned,
    likeCount: 2,
    commentCount: 1,
    shareCount: 0,
    viewCount: viewCount,
    createdAt: createdAt,
  );
}
