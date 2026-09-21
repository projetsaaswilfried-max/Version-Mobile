import '../entities/conversation_match.dart';
import '../entities/conversation_summary.dart';

enum MatchBannerMode {
  hidden,
  propose,
  pendingOutgoing,
  pendingIncoming,
  accepted,
}

MatchBannerMode matchBannerMode({
  required ConversationSummary? conversation,
  required ConversationMatch match,
}) {
  if (conversation == null || conversation.isSystem) {
    return MatchBannerMode.hidden;
  }
  if (conversation.status.trim().toUpperCase() == 'PENDING') {
    return MatchBannerMode.hidden;
  }
  switch (match.status) {
    case ConversationMatchStatus.none:
      return MatchBannerMode.propose;
    case ConversationMatchStatus.pending:
      return match.isIncoming
          ? MatchBannerMode.pendingIncoming
          : MatchBannerMode.pendingOutgoing;
    case ConversationMatchStatus.accepted:
      return MatchBannerMode.accepted;
  }
}
