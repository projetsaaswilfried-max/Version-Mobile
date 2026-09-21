import '../../../../core/parsing/json.dart';
import '../../domain/entities/conversation_match.dart';
import '../datasources/messages_schema.dart';

class ConversationMatchModel {
  const ConversationMatchModel._();

  static ConversationMatch fromRow({
    required Map<String, dynamic> row,
    required String currentUserId,
  }) {
    final json = Json(row);
    final id = json.stringOrNull('id') ?? json.intOrNull('id')?.toString();
    final statusRaw = (json.stringOrNull('status') ?? 'PENDING').toUpperCase();
    final proposer = _firstString(json, messagesMatchProposerColumns);

    final status = switch (statusRaw) {
      'ACCEPTED' => ConversationMatchStatus.accepted,
      'PENDING' => ConversationMatchStatus.pending,
      _ => ConversationMatchStatus.none,
    };

    if (status == ConversationMatchStatus.none) {
      return ConversationMatch.none;
    }

    return ConversationMatch(
      id: id,
      status: status,
      isIncoming: status == ConversationMatchStatus.pending &&
          proposer != null &&
          proposer != currentUserId,
    );
  }

  static String? _firstString(Json json, List<String> keys) {
    for (final key in keys) {
      final value = json.stringOrNull(key);
      if (value != null) return value;
    }
    return null;
  }
}
