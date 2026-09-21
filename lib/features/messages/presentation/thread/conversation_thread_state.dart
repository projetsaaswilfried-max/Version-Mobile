import 'package:equatable/equatable.dart';

import '../../domain/composer/thread_composer_mode.dart';
import '../../domain/entities/conversation_match.dart';
import '../../domain/entities/conversation_summary.dart';
import '../../domain/entities/message.dart';
import '../../domain/match/match_banner_mode.dart';

class ConversationThreadState extends Equatable {
  const ConversationThreadState({
    this.conversation,
    this.messages = const [],
    this.match = ConversationMatch.none,
    this.isLoading = false,
    this.sending = false,
    this.errorMessage,
    this.closed = false,
  });

  final ConversationSummary? conversation;
  final List<Message> messages;
  final ConversationMatch match;
  final bool isLoading;
  final bool sending;
  final String? errorMessage;
  final bool closed;

  ThreadComposerMode get composerMode {
    final c = conversation;
    if (c == null) return ThreadComposerMode.canCompose;
    return threadComposerMode(
      status: c.status,
      isSystem: c.isSystem,
      isIncomingInvite: c.isIncomingInvite,
    );
  }

  MatchBannerMode get matchBannerModeValue =>
      matchBannerMode(conversation: conversation, match: match);

  ConversationThreadState copyWith({
    ConversationSummary? conversation,
    List<Message>? messages,
    ConversationMatch? match,
    bool? isLoading,
    bool? sending,
    String? errorMessage,
    bool? closed,
    bool clearError = false,
    bool clearConversation = false,
  }) {
    return ConversationThreadState(
      conversation: clearConversation
          ? null
          : (conversation ?? this.conversation),
      messages: messages ?? this.messages,
      match: match ?? this.match,
      isLoading: isLoading ?? this.isLoading,
      sending: sending ?? this.sending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      closed: closed ?? this.closed,
    );
  }

  @override
  List<Object?> get props => [
    conversation,
    messages,
    match,
    isLoading,
    sending,
    errorMessage,
    closed,
  ];
}
