abstract class MessagesRemoteDataSource {
  Future<String> fetchSubscriptionStatus();
  Future<String> currentUserId();
  Future<List<AssembledConversationRow>> fetchConversationRows();
  Future<AssembledConversationRow?> fetchConversationRow(String id);
  Future<List<Map<String, dynamic>>> fetchMessageRows(String conversationId);
  Future<Map<String, dynamic>> insertTextMessage({
    required String conversationId,
    required String text,
  });
  Future<void> updateConversationStatus({
    required String conversationId,
    required String status,
  });
  Future<void> hideParticipation(String conversationId);
  Future<Map<String, dynamic>?> fetchActiveMatchRow(String conversationId);
  Future<Map<String, dynamic>> insertMatchProposal(String conversationId);
  Future<Map<String, dynamic>> updateMatchStatus({
    required String matchId,
    required String status,
  });
}

class AssembledConversationRow {
  const AssembledConversationRow({
    required this.conversation,
    required this.currentUserId,
    this.peer,
    this.latestMessage,
    this.lastReadAt,
    this.incomingCreatedAts = const [],
  });

  final Map<String, dynamic> conversation;
  final String currentUserId;
  final Map<String, dynamic>? peer;
  final Map<String, dynamic>? latestMessage;
  final DateTime? lastReadAt;
  final List<DateTime> incomingCreatedAts;
}
