import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../di/feed_providers.dart';
import '../domain/entities/post.dart';
import 'my_posts_state.dart';

class MyPostsController extends Notifier<MyPostsState> {
  var _loadGeneration = 0;

  @override
  MyPostsState build() {
    Future.microtask(load);
    return const MyPostsState(isLoading: true);
  }

  Future<void> load({bool silent = false}) async {
    final generation = ++_loadGeneration;
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    final result = await ref.read(listMyPostsProvider)();
    if (!ref.mounted || generation != _loadGeneration) return;
    switch (result) {
      case Ok<List<Post>>(:final value):
        state = state.copyWith(items: value, isLoading: false, clearError: true);
      case Err<List<Post>>(:final failure):
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
    }
  }

  Future<void> remove(String postId) async {
    final result = await ref.read(deletePersonalPostProvider)(postId);
    if (!ref.mounted) return;
    if (result case Ok()) {
      state = state.copyWith(
        items: [
          for (final item in state.items)
            if (item.id != postId) item,
        ],
      );
    } else if (result case Err(:final failure)) {
      state = state.copyWith(errorMessage: failure.message);
    }
  }
}

final myPostsControllerProvider =
    NotifierProvider.autoDispose<MyPostsController, MyPostsState>(
      MyPostsController.new,
    );
