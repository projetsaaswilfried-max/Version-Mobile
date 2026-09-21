import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/feed/di/feed_providers.dart';
import 'package:agapeo/features/feed/domain/entities/feed_filter.dart';
import 'package:agapeo/features/feed/domain/entities/feed_page.dart';
import 'package:agapeo/features/feed/domain/entities/personal_post_media.dart';
import 'package:agapeo/features/feed/domain/entities/post.dart';
import 'package:agapeo/features/feed/domain/entities/post_author.dart';
import 'package:agapeo/features/feed/domain/entities/post_category.dart';
import 'package:agapeo/features/feed/domain/entities/post_comment.dart';
import 'package:agapeo/features/feed/domain/entities/post_media_type.dart';
import 'package:agapeo/features/feed/domain/mapping/feed_chip.dart';
import 'package:agapeo/features/feed/domain/repositories/feed_repository.dart';
import 'package:agapeo/features/feed/presentation/feed_controller.dart';
import 'package:agapeo/features/feed/presentation/share/post_share_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFeedRepository implements FeedRepository {
  final calls = <({FeedFilter filter, int offset, int limit})>[];
  Result<FeedPage> Function(int offset) resultFor = (_) =>
      const Ok(FeedPage(items: [], hasMore: false));
  Result<void> likeResult = const Ok(null);
  Result<void> bookmarkResult = const Ok(null);
  final liked = <String, bool>{};
  final viewed = <String>[];
  final shared = <String>[];

  @override
  Future<Result<FeedPage>> fetchPage({
    required FeedFilter filter,
    required int offset,
    required int limit,
  }) async {
    calls.add((filter: filter, offset: offset, limit: limit));
    return resultFor(offset);
  }

  @override
  Future<Result<void>> setLiked(String postId, {required bool liked}) async {
    this.liked[postId] = liked;
    return likeResult;
  }

  @override
  Future<Result<void>> setBookmarked(
    String postId, {
    required bool bookmarked,
  }) async {
    return bookmarkResult;
  }

  @override
  Future<Result<void>> recordView(String postId) async {
    viewed.add(postId);
    return const Ok(null);
  }

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
    shared.add(postId);
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

class _FakeShareSheet implements PostShareSheet {
  bool completed = true;
  final texts = <String>[];

  @override
  Future<bool> share(String text) async {
    texts.add(text);
    return completed;
  }
}

Post _post(String id, {bool pinned = false}) {
  return Post(
    id: id,
    author: const PostAuthor(displayName: 'Agapeo'),
    body: 'body $id',
    mediaType: PostMediaType.textOnly,
    isPinned: pinned,
    likeCount: 0,
    commentCount: 0,
    shareCount: 0,
  );
}

void main() {
  late ProviderContainer container;
  late _FakeFeedRepository repo;
  late _FakeShareSheet sheet;

  Future<void> pumpMicrotasks() => Future<void>.delayed(Duration.zero);

  setUp(() {
    repo = _FakeFeedRepository();
    sheet = _FakeShareSheet();
    container = ProviderContainer(
      overrides: [
        feedRepositoryProvider.overrideWithValue(repo),
        postShareSheetProvider.overrideWithValue(sheet),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('load initial page on build', () async {
    repo.resultFor = (_) =>
        Ok(FeedPage(items: [_post('1'), _post('2')], hasMore: true));
    container.listen(feedControllerProvider, (_, _) {});
    await pumpMicrotasks();

    final state = container.read(feedControllerProvider);
    expect(state.items.map((p) => p.id), ['1', '2']);
    expect(state.hasMore, isTrue);
    expect(state.isInitialLoading, isFalse);
    expect(repo.calls.single.limit, 20);
    expect(repo.calls.single.offset, 0);
  });

  test('selectFilter resets list with new category', () async {
    repo.resultFor = (_) {
      if (repo.calls.length <= 1) {
        return Ok(FeedPage(items: [_post('1')], hasMore: false));
      }
      return Ok(FeedPage(items: [_post('t')], hasMore: false));
    };
    container.listen(feedControllerProvider, (_, _) {});
    await pumpMicrotasks();

    await container
        .read(feedControllerProvider.notifier)
        .selectFilter(FeedChip.teaching);
    await pumpMicrotasks();

    final state = container.read(feedControllerProvider);
    expect(state.selectedChip, FeedChip.teaching);
    expect(state.filter.category, PostCategory.teaching);
    expect(state.items.single.id, 't');
    expect(repo.calls.last.filter.category, PostCategory.teaching);
    expect(repo.calls.last.offset, 0);
  });

  test('refresh replaces items', () async {
    var page = 0;
    repo.resultFor = (_) {
      page += 1;
      return Ok(FeedPage(items: [_post('$page')], hasMore: false));
    };
    container.listen(feedControllerProvider, (_, _) {});
    await pumpMicrotasks();
    expect(container.read(feedControllerProvider).items.single.id, '1');

    await container.read(feedControllerProvider.notifier).refresh();
    expect(container.read(feedControllerProvider).items.single.id, '2');
    expect(container.read(feedControllerProvider).items.length, 1);
  });

  test('loadMore appends next page', () async {
    repo.resultFor = (offset) {
      if (offset == 0) {
        return Ok(FeedPage(items: [_post('a')], hasMore: true));
      }
      return Ok(FeedPage(items: [_post('b')], hasMore: false));
    };
    container.listen(feedControllerProvider, (_, _) {});
    await pumpMicrotasks();

    await container.read(feedControllerProvider.notifier).loadMore();
    final state = container.read(feedControllerProvider);
    expect(state.items.map((p) => p.id), ['a', 'b']);
    expect(state.hasMore, isFalse);
    expect(repo.calls.last.offset, 1);
  });

  test('initial error sets errorMessage', () async {
    repo.resultFor = (_) => const Err(NetworkFailure('Pas de réseau'));
    container.listen(feedControllerProvider, (_, _) {});
    await pumpMicrotasks();

    final state = container.read(feedControllerProvider);
    expect(state.errorMessage, 'Pas de réseau');
    expect(state.items, isEmpty);
    expect(state.isInitialLoading, isFalse);
  });

  test('loadMore error keeps items and sets snackbar', () async {
    repo.resultFor = (offset) {
      if (offset == 0) {
        return Ok(FeedPage(items: [_post('a')], hasMore: true));
      }
      return const Err(ServerFailure('boom'));
    };
    container.listen(feedControllerProvider, (_, _) {});
    await pumpMicrotasks();

    await container.read(feedControllerProvider.notifier).loadMore();
    final state = container.read(feedControllerProvider);
    expect(state.items.single.id, 'a');
    expect(state.snackbarMessage, 'boom');
    expect(state.isLoadingMore, isFalse);
  });

  test('plus chip does not change filter', () async {
    repo.resultFor = (_) => Ok(FeedPage(items: [_post('1')], hasMore: false));
    container.listen(feedControllerProvider, (_, _) {});
    await pumpMicrotasks();
    final calls = repo.calls.length;

    await container
        .read(feedControllerProvider.notifier)
        .selectFilter(FeedChip.plus);
    expect(container.read(feedControllerProvider).selectedChip, FeedChip.all);
    expect(repo.calls.length, calls);
  });

  test('toggleLike increments then rolls back on error', () async {
    repo.resultFor = (_) => Ok(FeedPage(items: [_post('1')], hasMore: false));
    container.listen(feedControllerProvider, (_, _) {});
    await pumpMicrotasks();
    expect(container.read(feedControllerProvider).items.single.likeCount, 0);

    await container.read(feedControllerProvider.notifier).toggleLike('1');
    expect(
      container.read(feedControllerProvider).items.single.likedByMe,
      isTrue,
    );
    expect(container.read(feedControllerProvider).items.single.likeCount, 1);
    expect(repo.liked['1'], isTrue);

    repo.likeResult = const Err(ServerFailure('like ko'));
    await container.read(feedControllerProvider.notifier).toggleLike('1');
    expect(
      container.read(feedControllerProvider).items.single.likedByMe,
      isTrue,
    );
    expect(container.read(feedControllerProvider).items.single.likeCount, 1);
    expect(container.read(feedControllerProvider).snackbarMessage, 'like ko');
  });

  test('bumpCommentCount updates the card counter', () async {
    repo.resultFor = (_) => Ok(FeedPage(items: [_post('1')], hasMore: false));
    container.listen(feedControllerProvider, (_, _) {});
    await pumpMicrotasks();

    container.read(feedControllerProvider.notifier).bumpCommentCount('1');
    expect(container.read(feedControllerProvider).items.single.commentCount, 1);
  });

  test('recordView ignores duplicates', () async {
    repo.resultFor = (_) => Ok(FeedPage(items: [_post('2')], hasMore: false));
    container.listen(feedControllerProvider, (_, _) {});
    await pumpMicrotasks();

    final post = container.read(feedControllerProvider).items.single;
    await container.read(feedControllerProvider.notifier).recordView(post);
    await container.read(feedControllerProvider.notifier).recordView(post);
    expect(repo.viewed, ['2']);
  });

  test('sharePost opens sheet then records and increments', () async {
    repo.resultFor = (_) => Ok(FeedPage(items: [_post('1')], hasMore: false));
    container.listen(feedControllerProvider, (_, _) {});
    await pumpMicrotasks();
    final post = container.read(feedControllerProvider).items.single;

    await container.read(feedControllerProvider.notifier).sharePost(post);
    expect(sheet.texts, ['body 1']);
    expect(repo.shared, ['1']);
    expect(container.read(feedControllerProvider).items.single.shareCount, 1);
  });

  test('sharePost dismissed does not record', () async {
    sheet.completed = false;
    repo.resultFor = (_) => Ok(FeedPage(items: [_post('1')], hasMore: false));
    container.listen(feedControllerProvider, (_, _) {});
    await pumpMicrotasks();
    final post = container.read(feedControllerProvider).items.single;

    await container.read(feedControllerProvider.notifier).sharePost(post);
    expect(repo.shared, isEmpty);
    expect(container.read(feedControllerProvider).items.single.shareCount, 0);
  });
}
