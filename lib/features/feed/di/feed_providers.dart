import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/di/providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/datasources/supabase_feed_datasource.dart';
import '../data/repositories/feed_repository_impl.dart';
import '../domain/entities/feed_filter.dart';
import '../domain/entities/feed_page.dart';
import '../domain/entities/personal_post_media.dart';
import '../domain/entities/post.dart';
import '../domain/entities/post_comment.dart';
import '../domain/repositories/feed_repository.dart';
import '../domain/usecases/add_post_comment.dart';
import '../domain/usecases/create_personal_post.dart';
import '../domain/usecases/delete_personal_post.dart';
import '../domain/usecases/get_feed.dart';
import '../domain/usecases/list_my_posts.dart';
import '../domain/usecases/list_personal_posts.dart';
import '../domain/usecases/list_post_comments.dart';
import '../domain/usecases/record_post_share.dart';
import '../domain/usecases/record_post_view.dart';
import '../domain/usecases/toggle_post_bookmark.dart';
import '../domain/usecases/toggle_post_like.dart';
import '../domain/usecases/update_personal_post.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  final env = AppEnvironment.current;
  if (env.supabaseUrl.isEmpty || env.supabaseAnonKey.isEmpty) {
    return const UnconfiguredFeedRepository();
  }
  return FeedRepositoryImpl(
    SupabaseFeedDataSource(ref.watch(supabaseClientProvider)),
  );
});

final getFeedProvider = Provider(
  (ref) => GetFeed(ref.watch(feedRepositoryProvider)),
);

final togglePostLikeProvider = Provider(
  (ref) => TogglePostLike(ref.watch(feedRepositoryProvider)),
);

final togglePostBookmarkProvider = Provider(
  (ref) => TogglePostBookmark(ref.watch(feedRepositoryProvider)),
);

final recordPostViewProvider = Provider(
  (ref) => RecordPostView(ref.watch(feedRepositoryProvider)),
);

final listPostCommentsProvider = Provider(
  (ref) => ListPostComments(ref.watch(feedRepositoryProvider)),
);

final addPostCommentProvider = Provider(
  (ref) => AddPostComment(ref.watch(feedRepositoryProvider)),
);

final recordPostShareProvider = Provider(
  (ref) => RecordPostShare(ref.watch(feedRepositoryProvider)),
);

final listMyPostsProvider = Provider(
  (ref) => ListMyPosts(ref.watch(feedRepositoryProvider)),
);

final listPersonalPostsProvider = Provider(
  (ref) => ListPersonalPosts(ref.watch(feedRepositoryProvider)),
);

/// Posts `PERSONAL` d'un auteur (profil public / fiche Découvrir).
final personalPostsByAuthorProvider =
    FutureProvider.autoDispose.family<List<Post>, String>((ref, authorId) async {
      final result = await ref.watch(listPersonalPostsProvider)(authorId);
      return switch (result) {
        Ok(:final value) => value,
        Err() => const <Post>[],
      };
    });

final createPersonalPostProvider = Provider(
  (ref) => CreatePersonalPost(ref.watch(feedRepositoryProvider)),
);

final updatePersonalPostProvider = Provider(
  (ref) => UpdatePersonalPost(ref.watch(feedRepositoryProvider)),
);

final deletePersonalPostProvider = Provider(
  (ref) => DeletePersonalPost(ref.watch(feedRepositoryProvider)),
);

class UnconfiguredFeedRepository implements FeedRepository {
  const UnconfiguredFeedRepository();

  static const failure = ServerFailure(
    'Supabase non configuré : lance avec --dart-define=SUPABASE_URL=... '
    '--dart-define=SUPABASE_ANON_KEY=...',
  );

  @override
  Future<Result<FeedPage>> fetchPage({
    required FeedFilter filter,
    required int offset,
    required int limit,
  }) async => const Err(failure);

  @override
  Future<Result<void>> setLiked(String postId, {required bool liked}) async =>
      const Err(failure);

  @override
  Future<Result<void>> setBookmarked(
    String postId, {
    required bool bookmarked,
  }) async => const Err(failure);

  @override
  Future<Result<void>> recordView(String postId) async => const Err(failure);

  @override
  Future<Result<List<PostComment>>> fetchComments(String postId) async =>
      const Err(failure);

  @override
  Future<Result<PostComment>> addComment(
    String postId,
    String body, {
    String? parentId,
  }) async => const Err(failure);

  @override
  Future<Result<void>> recordShare(String postId) async => const Err(failure);

  @override
  Future<Result<List<Post>>> fetchMyPosts() async => const Err(failure);

  @override
  Future<Result<List<Post>>> fetchPersonalPostsByAuthor(String authorId) async =>
      const Err(failure);

  @override
  Future<Result<Post>> createPersonalPost({
    required String body,
    PersonalPostMedia? media,
  }) async => const Err(failure);

  @override
  Future<Result<Post>> updatePersonalPost({
    required String postId,
    required String body,
  }) async => const Err(failure);

  @override
  Future<Result<void>> deletePersonalPost(String postId) async =>
      const Err(failure);
}
