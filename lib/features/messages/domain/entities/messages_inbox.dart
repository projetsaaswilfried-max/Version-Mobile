import 'package:equatable/equatable.dart';

import 'conversation_summary.dart';

class MessagesInbox extends Equatable {
  const MessagesInbox({required this.conversations});

  final List<ConversationSummary> conversations;

  @override
  List<Object?> get props => [conversations];
}
