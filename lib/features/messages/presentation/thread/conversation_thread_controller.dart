import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/error/result.dart';
import '../../di/messages_providers.dart';
import '../../domain/entities/conversation_match.dart';
import '../../domain/entities/conversation_summary.dart';
import '../../domain/entities/message.dart';
import '../messages_controller.dart';
import 'conversation_thread_state.dart';

class ConversationThreadController extends Notifier<ConversationThreadState> {
  ConversationThreadController(this.conversationId);

  final String conversationId;

  /// Ignore late responses from an older [load] / [refreshMessages].
  var _loadGeneration = 0;

  @override
  ConversationThreadState build() {
    try {
      if (!kUseFakeMessagesConversations) {
        final client = ref.read(supabaseClientProvider);
        final channel = client
            .channel('thread-$conversationId')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'messages',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'conversation_id',
                value: conversationId,
              ),
              callback: (_) {
                // Soft refresh only - never flip isLoading (that replaced the
                // whole thread with a spinner after each send / peer message).
                if (ref.mounted) refreshMessages();
              },
            )
            .subscribe();
        ref.onDispose(() {
          client.removeChannel(channel);
        });
      }
    } catch (_) {}
    Future.microtask(load);
    return const ConversationThreadState(isLoading: true);
  }

  Future<void> load({bool silent = false}) async {
    final generation = ++_loadGeneration;
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    final convResult = await ref.read(getConversationProvider)(conversationId);
    final messagesResult = await ref.read(getMessagesProvider)(conversationId);
    final matchResult = await ref
        .read(messagesRepositoryProvider)
        .fetchMatch(conversationId);
    if (!ref.mounted || generation != _loadGeneration) return;

    switch (convResult) {
      case Err<ConversationSummary?>(:final failure):
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return;
      case Ok<ConversationSummary?>(:final value):
        final conversation = value;
        if (conversation == null) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Conversation introuvable.',
            clearConversation: true,
          );
          return;
        }
        final match = switch (matchResult) {
          Ok<ConversationMatch>(:final value) => value,
          Err() => ConversationMatch.none,
        };
        switch (messagesResult) {
          case Err<List<Message>>(:final failure):
            state = state.copyWith(
              conversation: conversation,
              match: match,
              isLoading: false,
              errorMessage: failure.message,
            );
          case Ok<List<Message>>(:final value):
            state = state.copyWith(
              conversation: conversation,
              messages: value,
              match: match,
              isLoading: false,
              clearError: true,
            );
        }
    }
  }

  /// Relit uniquement les messages, sans spinner plein écran.
  Future<void> refreshMessages() async {
    final generation = ++_loadGeneration;
    final messagesResult = await ref.read(getMessagesProvider)(conversationId);
    if (!ref.mounted || generation != _loadGeneration) return;
    switch (messagesResult) {
      case Ok<List<Message>>(:final value):
        state = state.copyWith(messages: value, clearError: true);
      case Err<List<Message>>():
        break;
    }
  }

  Future<void> send(String text) async {
    if (state.sending) return;
    state = state.copyWith(sending: true, clearError: true);
    final result = await ref.read(sendTextMessageProvider)(
      conversationId: conversationId,
      text: text,
    );
    if (!ref.mounted) return;
    switch (result) {
      case Ok<Message>(:final value):
        state = state.copyWith(
          messages: _upsertMessage(state.messages, value),
          sending: false,
        );
      case Err<Message>(:final failure):
        state = state.copyWith(sending: false, errorMessage: failure.message);
    }
  }

  Future<void> accept() async {
    final result = await ref.read(acceptConversationInvitationProvider)(
      conversationId,
    );
    if (!ref.mounted) return;
    switch (result) {
      case Ok<void>():
        await load(silent: true);
        if (ref.mounted) {
          await ref.read(messagesControllerProvider.notifier).refresh();
        }
      case Err<void>(:final failure):
        state = state.copyWith(errorMessage: failure.message);
    }
  }

  Future<void> decline() async {
    final result = await ref.read(declineConversationInvitationProvider)(
      conversationId,
    );
    if (!ref.mounted) return;
    switch (result) {
      case Ok<void>():
        state = state.copyWith(closed: true);
        await ref.read(messagesControllerProvider.notifier).refresh();
      case Err<void>(:final failure):
        state = state.copyWith(errorMessage: failure.message);
    }
  }

  Future<void> proposeMatch() => _mutateMatch(
    () => ref.read(messagesRepositoryProvider).proposeMatch(conversationId),
  );

  Future<void> acceptMatch() => _mutateMatch(
    () => ref.read(messagesRepositoryProvider).acceptMatch(conversationId),
  );

  Future<void> declineMatch() => _mutateMatch(
    () => ref.read(messagesRepositoryProvider).declineMatch(conversationId),
  );

  Future<void> cancelMatch() => _mutateMatch(
    () => ref.read(messagesRepositoryProvider).cancelMatch(conversationId),
  );

  Future<void> hide() async {
    final result = await ref
        .read(messagesRepositoryProvider)
        .hideConversation(conversationId);
    if (!ref.mounted) return;
    switch (result) {
      case Ok<void>():
        state = state.copyWith(closed: true);
        await ref.read(messagesControllerProvider.notifier).refresh();
      case Err<void>(:final failure):
        state = state.copyWith(errorMessage: failure.message);
    }
  }

  Future<void> _mutateMatch(
    Future<Result<ConversationMatch>> Function() action,
  ) async {
    final result = await action();
    if (!ref.mounted) return;
    switch (result) {
      case Ok<ConversationMatch>(:final value):
        state = state.copyWith(match: value, clearError: true);
      case Err<ConversationMatch>(:final failure):
        state = state.copyWith(errorMessage: failure.message);
    }
  }

  static List<Message> _upsertMessage(List<Message> current, Message next) {
    if (current.any((m) => m.id == next.id)) return current;
    return [...current, next];
  }
}

final conversationThreadControllerProvider = NotifierProvider.autoDispose
    .family<ConversationThreadController, ConversationThreadState, String>(
      ConversationThreadController.new,
    );
