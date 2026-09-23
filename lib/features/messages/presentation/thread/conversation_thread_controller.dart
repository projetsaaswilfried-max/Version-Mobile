import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/error/result.dart';
import '../../../discover/domain/premium/discover_premium_gate.dart';
import '../../../profile/di/profile_providers.dart';
import '../../di/messages_providers.dart';
import '../../domain/composer/thread_composer_mode.dart';
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

  /// Filet de secours pour le destinataire (D34-like) : le realtime ne
  /// déclenche qu'un seul refresh, sur l'INSERT de `messages`, qui arrive
  /// avant que `message_attachments`/l'URL signée n'existent côté serveur.
  /// Contrairement à l'expéditeur (qui reçoit sa propre réponse déjà
  /// hydratée via sendImage/sendVoice), le destinataire n'a aucun autre
  /// déclencheur - sans ce filet, sa photo reste bloquée sur le
  /// placeholder tant qu'il ne rouvre pas la conversation.
  Timer? _mediaRetryTimer;
  var _mediaRetryCount = 0;
  static const _maxMediaRetries = 4;
  static const _mediaRetryDelay = Duration(milliseconds: 1500);

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
    ref.onDispose(() => _mediaRetryTimer?.cancel());
    Future.microtask(load);
    return const ConversationThreadState(isLoading: true);
  }

  Future<void> load({bool silent = false}) async {
    final generation = ++_loadGeneration;
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    // Les 4 lectures sont indépendantes : les lancer ensemble plutôt que
    // les attendre une par une divise le temps de chargement par ~4.
    final convFuture = ref.read(getConversationProvider)(conversationId);
    final messagesFuture = ref.read(getMessagesProvider)(conversationId);
    final matchFuture = ref
        .read(messagesRepositoryProvider)
        .fetchMatch(conversationId);
    final gateFuture = ref.read(profileGateRepositoryProvider).fetchGate();
    final convResult = await convFuture;
    final messagesResult = await messagesFuture;
    final matchResult = await matchFuture;
    final gateResult = await gateFuture;
    if (!ref.mounted || generation != _loadGeneration) return;

    final premiumActive = switch (gateResult) {
      Ok(:final value) => isPremiumActive(
        subscriptionStatus: value.subscriptionStatus.name.toUpperCase(),
      ),
      Err() =>
        true, // Soft-fail : ne pas bloquer l'écriture sur une panne réseau.
    };
    state = state.copyWith(isPremiumActive: premiumActive);

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
            _scheduleMediaRetryIfNeeded(value, generation);
            unawaited(_markRead());
        }
    }
  }

  /// Marque la discussion comme lue à l'ouverture (`last_read_at`) - jamais
  /// écrit ailleurs jusqu'ici, le badge non-lu ne retombait donc jamais.
  Future<void> _markRead() async {
    final result = await ref
        .read(messagesRepositoryProvider)
        .markConversationRead(conversationId);
    if (!ref.mounted || result is! Ok<void>) return;
    await ref.read(messagesControllerProvider.notifier).refresh();
  }

  /// Relit uniquement les messages, sans spinner plein écran.
  Future<void> refreshMessages() async {
    final generation = ++_loadGeneration;
    final messagesResult = await ref.read(getMessagesProvider)(conversationId);
    if (!ref.mounted || generation != _loadGeneration) return;
    switch (messagesResult) {
      case Ok<List<Message>>(:final value):
        final merged = _mergeMessages(state.messages, value);
        state = state.copyWith(messages: merged, clearError: true);
        _scheduleMediaRetryIfNeeded(merged, generation);
      case Err<List<Message>>():
        break;
    }
  }

  static bool _isPendingMedia(Message m) =>
      (m.type == MessageType.image || m.type == MessageType.voice) &&
      (m.mediaUrl?.isEmpty ?? true);

  void _scheduleMediaRetryIfNeeded(List<Message> messages, int generation) {
    _mediaRetryTimer?.cancel();
    if (!messages.any(_isPendingMedia) ||
        _mediaRetryCount >= _maxMediaRetries) {
      _mediaRetryCount = 0;
      return;
    }
    _mediaRetryCount++;
    _mediaRetryTimer = Timer(_mediaRetryDelay, () {
      if (!ref.mounted || generation != _loadGeneration) return;
      refreshMessages();
    });
  }

  /// Le realtime déclenche un refresh dès l'INSERT du message, avant que
  /// l'upload/l'attachment/la signature d'URL d'une image ne soient
  /// terminés côté serveur - le refetch peut donc arriver avec un
  /// media_url encore vide et écraser la version déjà hydratée en
  /// mémoire (photo qui n'affichait plus qu'un placeholder tant qu'on
  /// ne rouvrait pas la conversation).
  static List<Message> _mergeMessages(
    List<Message> current,
    List<Message> incoming,
  ) {
    final byId = {for (final m in current) m.id: m};
    return [
      for (final m in incoming)
        if (byId[m.id] case final existing?
            when (existing.mediaUrl?.isNotEmpty ?? false) &&
                !(m.mediaUrl?.isNotEmpty ?? false))
          existing
        else
          m,
    ];
  }

  Future<void> send(String text) async {
    if (state.sending) return;
    // Défense en profondeur : le composer est déjà masqué côté UI
    // (ThreadComposerMode.premiumRequired) quand ce n'est pas le cas.
    if (state.composerMode == ThreadComposerMode.premiumRequired) return;
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

  Future<void> sendImage(String localPath) async {
    if (state.sending) return;
    // Défense en profondeur : le composer est déjà masqué côté UI
    // (ThreadComposerMode.premiumRequired) quand ce n'est pas le cas.
    if (state.composerMode == ThreadComposerMode.premiumRequired) return;
    state = state.copyWith(sending: true, clearError: true);
    final result = await ref.read(sendImageMessageProvider)(
      conversationId: conversationId,
      localPath: localPath,
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

  Future<void> sendVoice(
    String localPath, {
    required int durationSeconds,
  }) async {
    if (state.sending) return;
    if (state.composerMode == ThreadComposerMode.premiumRequired) return;
    state = state.copyWith(sending: true, clearError: true);
    final result = await ref.read(sendVoiceMessageProvider)(
      conversationId: conversationId,
      localPath: localPath,
      durationSeconds: durationSeconds,
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

  Future<void> deleteMessage(String messageId) async {
    final result = await ref
        .read(messagesRepositoryProvider)
        .deleteMessage(messageId);
    if (!ref.mounted) return;
    switch (result) {
      case Ok<void>():
        await refreshMessages();
      case Err<void>(:final failure):
        state = state.copyWith(errorMessage: failure.message);
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

  Future<void> proposeMatch() async {
    final recipientId = state.conversation?.peerId;
    if (recipientId == null) {
      state = state.copyWith(errorMessage: 'Membre introuvable.');
      return;
    }
    await _mutateMatch(
      () => ref
          .read(messagesRepositoryProvider)
          .proposeMatch(conversationId, recipientId: recipientId),
    );
  }

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

  /// Remplace le message existant plutôt que de l'ignorer : le realtime
  /// peut déclencher un `refreshMessages()` sur notre propre INSERT avant
  /// que l'upload/l'URL signée ne soit prête côté client, insérant un
  /// placeholder pour cet id avant même que `send()`/`sendImage()` ne
  /// reçoive sa propre réponse (déjà hydratée) - sans ce remplacement, la
  /// version correcte était jetée silencieusement.
  static List<Message> _upsertMessage(List<Message> current, Message next) {
    final index = current.indexWhere((m) => m.id == next.id);
    if (index == -1) return [...current, next];
    return [
      for (var i = 0; i < current.length; i++) i == index ? next : current[i],
    ];
  }
}

final conversationThreadControllerProvider = NotifierProvider.autoDispose
    .family<ConversationThreadController, ConversationThreadState, String>(
      ConversationThreadController.new,
    );
