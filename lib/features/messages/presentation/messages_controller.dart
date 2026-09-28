import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../di/messages_providers.dart';
import '../domain/entities/messages_inbox.dart';
import 'messages_state.dart';

class MessagesController extends Notifier<MessagesState> {
  @override
  MessagesState build() {
    Future<void>.microtask(loadInitial);
    return const MessagesState(isInitialLoading: true);
  }

  Future<void> loadInitial() => _load(refreshing: false);

  Future<void> retry() => _load(refreshing: false);

  Future<void> refresh() => _load(refreshing: true);

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> _load({required bool refreshing}) async {
    if (refreshing) {
      state = state.copyWith(isRefreshing: true, clearError: true);
    } else {
      state = state.copyWith(
        isInitialLoading: true,
        conversations: const [],
        clearError: true,
      );
    }

    final result = await ref.read(getConversationsProvider)();
    if (!ref.mounted) return;
    switch (result) {
      case Ok<MessagesInbox>(:final value):
        state = state.copyWith(
          conversations: value.conversations,
          isInitialLoading: false,
          isRefreshing: false,
          clearError: true,
        );
      case Err<MessagesInbox>(:final failure):
        if (refreshing && state.conversations.isNotEmpty) {
          state = state.copyWith(isRefreshing: false, isInitialLoading: false);
        } else {
          state = state.copyWith(
            isInitialLoading: false,
            isRefreshing: false,
            conversations: const [],
            errorMessage: failure.message,
          );
        }
    }
  }
}

final messagesControllerProvider =
    NotifierProvider.autoDispose<MessagesController, MessagesState>(
      MessagesController.new,
    );
