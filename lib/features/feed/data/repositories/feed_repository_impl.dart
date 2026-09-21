import '../../../../core/error/map_data_exception.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/feed_filter.dart';
import '../../domain/entities/feed_page.dart';
import '../../domain/entities/personal_post_media.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_author.dart';
import '../../domain/entities/post_comment.dart';
import '../../domain/entities/post_media_type.dart';
import '../../domain/mapping/post_db_mapping.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_remote_datasource.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';

class FeedRepositoryImpl implements FeedRepository {
  FeedRepositoryImpl(this._remote);

  final FeedRemoteDataSource _remote;

  @override
  Future<Result<FeedPage>> fetchPage({
    required FeedFilter filter,
    required int offset,
    required int limit,
  }) async {
    try {
      final rows = await _remote.fetchPosts(
        filter: filter,
        offset: offset,
        limit: limit,
      );
      final parsed = <Post>[
        for (final row in rows)
          if (PostModel.fromJson(row) case final post?) post,
      ];
      final ids = [for (final post in parsed) post.id];
      final liked = await _remote.fetchLikedPostIds(ids);
      final bookmarked = await _remote.fetchBookmarkedPostIds(ids);
      final items = [
        for (final post in parsed)
          post.copyWith(
            likedByMe: liked.contains(post.id),
            bookmarkedByMe: bookmarked.contains(post.id),
          ),
      ];
      return Ok(FeedPage(items: items, hasMore: rows.length >= limit));
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<void>> setLiked(String postId, {required bool liked}) async {
    try {
      await _remote.setPostLiked(postId, liked: liked);
      return const Ok(null);
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<void>> setBookmarked(
    String postId, {
    required bool bookmarked,
  }) async {
    try {
      await _remote.setPostBookmarked(postId, bookmarked: bookmarked);
      return const Ok(null);
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<void>> recordView(String postId) async {
    try {
      await _remote.recordPostView(postId);
      return const Ok(null);
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<List<PostComment>>> fetchComments(String postId) async {
    try {
      final rows = await _remote.fetchComments(postId);
      return Ok([
        for (final row in rows)
          if (CommentModel.fromJson(row) case final comment?) comment,
      ]);
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<PostComment>> addComment(
    String postId,
    String body, {
    String? parentId,
  }) async {
    try {
      final row = await _remote.insertComment(postId, body, parentId: parentId);
      final comment = CommentModel.fromJson(row);
      if (comment == null) {
        final rawId = row['id'];
        final id = rawId == null || '$rawId'.isEmpty
            ? 'local-${DateTime.now().microsecondsSinceEpoch}'
            : '$rawId';
        return Ok(
          PostComment(
            id: id,
            body: body,
            authorName: 'Moi',
            parentId: parentId,
          ),
        );
      }
      return Ok(comment);
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<void>> recordShare(String postId) async {
    try {
      await _remote.recordPostShare(postId);
      return const Ok(null);
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<List<Post>>> fetchMyPosts() async {
    try {
      final rows = await _remote.fetchMyPosts();
      return Ok([
        for (final row in rows)
          if (PostModel.fromJson(row, includePersonal: true) case final post?)
            post,
      ]);
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<List<Post>>> fetchPersonalPostsByAuthor(String authorId) async {
    try {
      final rows = await _remote.fetchPersonalPostsByAuthor(authorId);
      return Ok([
        for (final row in rows)
          if (PostModel.fromJson(row, includePersonal: true) case final post?)
            post,
      ]);
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<Post>> createPersonalPost({
    required String body,
    PersonalPostMedia? media,
  }) async {
    try {
      final mediaType = media == null
          ? PostMediaType.textOnly
          : (media.isVideo ? PostMediaType.video : PostMediaType.image);
      final row = await _remote.insertPersonalPost(
        body: body,
        mediaType: mediaTypeToDb(mediaType),
      );
      final id = row['id'];
      if (media != null && id is String) {
        await _remote.attachPersonalMedia(
          postId: id,
          localPath: media.localPath,
          isVideo: media.isVideo,
        );
      }
      final created = PostModel.fromJson(row, includePersonal: true);
      if (created != null) return Ok(created);
      return Ok(
        Post(
          id: id is String ? id : body,
          author: const PostAuthor(displayName: 'Moi'),
          body: body,
          mediaType: mediaType,
          isPinned: false,
          likeCount: 0,
          commentCount: 0,
          shareCount: 0,
        ),
      );
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<Post>> updatePersonalPost({
    required String postId,
    required String body,
  }) async {
    try {
      final row = await _remote.updatePersonalPost(postId: postId, body: body);
      final updated = PostModel.fromJson(row, includePersonal: true);
      if (updated != null) return Ok(updated);
      return Ok(
        Post(
          id: postId,
          author: const PostAuthor(displayName: 'Moi'),
          body: body,
          mediaType: PostMediaType.textOnly,
          isPinned: false,
          likeCount: 0,
          commentCount: 0,
          shareCount: 0,
        ),
      );
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<void>> deletePersonalPost(String postId) async {
    try {
      await _remote.deletePersonalPost(postId);
      return const Ok(null);
    } catch (error) {
      return Err(mapDataException(error));
    }
  }
}
