import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../di/feed_providers.dart';
import '../domain/comments/comment_threads.dart';
import '../domain/entities/post_comment.dart';
import 'feed_comments_state.dart';
import 'feed_controller.dart';

class FeedCommentsController extends Notifier<FeedCommentsState> {
  FeedCommentsController(this.postId);

  final String postId;

  @override
  FeedCommentsState build() {
    Future<void>.microtask(load);
    return const FeedCommentsState(isLoading: true);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await ref.read(listPostCommentsProvider)(postId);
    if (!ref.mounted) return;
    switch (result) {
      case Ok(:final value):
        state = state.copyWith(comments: value, isLoading: false);
      case Err(:final failure):
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
    }
  }

  void startReply(PostComment comment) {
    state = state.copyWith(replyTo: replyTarget(comment, state.comments));
  }

  void clearReply() {
    state = state.copyWith(clearReply: true);
  }

  Future<bool> send(String body) async {
    if (state.sending) return false;
    final parentId = state.replyTo?.id;
    state = state.copyWith(sending: true, clearError: true);
    final feed = ref.read(feedControllerProvider.notifier);
    feed.bumpCommentCount(postId);
    final result = await ref.read(addPostCommentProvider)(
      postId,
      body,
      parentId: parentId,
    );
    switch (result) {
      case Ok(:final value):
        if (ref.mounted) {
          state = state.copyWith(
            comments: [...state.comments, value],
            sending: false,
            clearReply: true,
          );
        }
        return true;
      case Err(:final failure):
        feed.bumpCommentCount(postId, delta: -1);
        if (ref.mounted) {
          state = state.copyWith(sending: false, errorMessage: failure.message);
        }
        return false;
    }
  }
}

final feedCommentsProvider = NotifierProvider.autoDispose
    .family<FeedCommentsController, FeedCommentsState, String>(
      FeedCommentsController.new,
    );
