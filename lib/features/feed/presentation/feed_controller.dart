import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../di/feed_providers.dart';
import '../domain/entities/feed_page.dart';
import '../domain/entities/post.dart';
import '../domain/mapping/feed_chip.dart';
import '../domain/share/post_share_text.dart';
import 'feed_state.dart';
import 'share/post_share_sheet.dart';

class FeedController extends Notifier<FeedState> {
  final _viewed = <String>{};

  @override
  FeedState build() {
    Future<void>.microtask(loadInitial);
    return const FeedState(isInitialLoading: true);
  }

  Future<void> loadInitial() => _load(reset: true, refreshing: false);

  Future<void> retry() => _load(reset: true, refreshing: false);

  Future<void> refresh() => _load(reset: true, refreshing: true);

  Future<void> selectFilter(FeedChip chip) async {
    if (chip.isOverflowTrigger) return;
    if (state.selectedChip == chip && !state.isInitialLoading) return;
    state = FeedState(
      filter: chip.filter,
      selectedChip: chip,
      isInitialLoading: true,
    );
    await _load(reset: true, refreshing: false);
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.isLoadingMore ||
        state.isInitialLoading ||
        state.isRefreshing) {
      return;
    }
    state = state.copyWith(isLoadingMore: true, clearSnackbar: true);
    final result = await ref.read(getFeedProvider)(
      filter: state.filter,
      offset: state.items.length,
    );
    if (!ref.mounted) return;
    switch (result) {
      case Ok<FeedPage>(:final value):
        state = state.copyWith(
          items: [...state.items, ...value.items],
          hasMore: value.hasMore,
          isLoadingMore: false,
        );
      case Err<FeedPage>(:final failure):
        state = state.copyWith(
          isLoadingMore: false,
          snackbarMessage: failure.message,
        );
    }
  }

  void clearSnackbar() {
    state = state.copyWith(clearSnackbar: true);
  }

  Future<void> toggleLike(String postId) async {
    final current = _byId(postId);
    if (current == null) return;
    final liked = !current.likedByMe;
    final next = current.copyWith(
      likedByMe: liked,
      likeCount: liked
          ? current.likeCount + 1
          : (current.likeCount - 1).clamp(0, 1 << 30),
    );
    _replace(next);
    final result = await ref.read(togglePostLikeProvider)(postId, liked: liked);
    if (!ref.mounted) return;
    if (result case Err(:final failure)) {
      _replace(current);
      state = state.copyWith(snackbarMessage: failure.message);
    }
  }

  Future<void> toggleBookmark(String postId) async {
    final current = _byId(postId);
    if (current == null) return;
    final bookmarked = !current.bookmarkedByMe;
    _replace(current.copyWith(bookmarkedByMe: bookmarked));
    final result = await ref.read(togglePostBookmarkProvider)(
      postId,
      bookmarked: bookmarked,
    );
    if (!ref.mounted) return;
    if (result case Err(:final failure)) {
      _replace(current);
      state = state.copyWith(snackbarMessage: failure.message);
    }
  }

  Future<void> recordView(Post post) async {
    if (_viewed.contains(post.id)) return;
    _viewed.add(post.id);
    await ref.read(recordPostViewProvider)(post.id);
  }

  void bumpCommentCount(String postId, {int delta = 1}) {
    final current = _byId(postId);
    if (current == null) return;
    _replace(
      current.copyWith(
        commentCount: (current.commentCount + delta).clamp(0, 1 << 30),
      ),
    );
  }

  Future<void> sharePost(Post post) async {
    final completed = await ref
        .read(postShareSheetProvider)
        .share(postShareText(post));
    if (!completed || !ref.mounted) return;
    final current = _byId(post.id);
    if (current != null) {
      _replace(current.copyWith(shareCount: current.shareCount + 1));
    }
    await ref.read(recordPostShareProvider)(post.id);
  }

  Post? _byId(String id) {
    for (final item in state.items) {
      if (item.id == id) return item;
    }
    return null;
  }

  void _replace(Post post) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == post.id) post else item,
      ],
    );
  }

  Future<void> _load({required bool reset, required bool refreshing}) async {
    if (refreshing) {
      state = state.copyWith(
        isRefreshing: true,
        clearError: true,
        clearSnackbar: true,
      );
    } else if (reset) {
      state = state.copyWith(
        isInitialLoading: true,
        items: const [],
        clearError: true,
        clearSnackbar: true,
      );
    }

    final result = await ref.read(getFeedProvider)(
      filter: state.filter,
      offset: 0,
    );
    if (!ref.mounted) return;
    switch (result) {
      case Ok<FeedPage>(:final value):
        state = state.copyWith(
          items: value.items,
          hasMore: value.hasMore,
          isInitialLoading: false,
          isRefreshing: false,
          clearError: true,
        );
      case Err<FeedPage>(:final failure):
        if (refreshing && state.items.isNotEmpty) {
          state = state.copyWith(
            isRefreshing: false,
            isInitialLoading: false,
            snackbarMessage: failure.message,
          );
        } else {
          state = state.copyWith(
            isInitialLoading: false,
            isRefreshing: false,
            items: const [],
            errorMessage: failure.message,
          );
        }
    }
  }
}

final feedControllerProvider =
    NotifierProvider.autoDispose<FeedController, FeedState>(FeedController.new);
