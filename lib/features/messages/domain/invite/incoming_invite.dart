bool isIncomingConversationInvite({
  required String status,
  required String currentUserId,
  String? initiatorId,
}) {
  if (status.toUpperCase() != 'PENDING') return false;
  if (initiatorId == null || initiatorId.isEmpty) return false;
  return initiatorId != currentUserId;
}
