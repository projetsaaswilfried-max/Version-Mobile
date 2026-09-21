import 'package:equatable/equatable.dart';

enum ConversationMatchStatus { none, pending, accepted }

class ConversationMatch extends Equatable {
  const ConversationMatch({
    this.id,
    this.status = ConversationMatchStatus.none,
    this.isIncoming = false,
  });

  final String? id;
  final ConversationMatchStatus status;
  final bool isIncoming;

  static const none = ConversationMatch();

  @override
  List<Object?> get props => [id, status, isIncoming];
}
