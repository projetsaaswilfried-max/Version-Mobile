int countUnreadMessages({
  required DateTime? lastReadAt,
  required List<DateTime> incomingCreatedAts,
}) {
  if (lastReadAt == null) return incomingCreatedAts.length;
  return incomingCreatedAts.where((at) => at.isAfter(lastReadAt)).length;
}
