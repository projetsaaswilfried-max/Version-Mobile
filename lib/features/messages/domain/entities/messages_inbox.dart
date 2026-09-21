import 'package:equatable/equatable.dart';

import 'conversation_summary.dart';

class MessagesInbox extends Equatable {
  const MessagesInbox({required this.conversations, this.expired = false});

  final List<ConversationSummary> conversations;
  final bool expired;

  @override
  List<Object?> get props => [conversations, expired];
}
