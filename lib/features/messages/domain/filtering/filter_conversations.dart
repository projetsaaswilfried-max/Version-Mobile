import '../entities/conversation_summary.dart';

List<ConversationSummary> filterConversations(
  List<ConversationSummary> items,
  String query,
) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return items;
  return [
    for (final item in items)
      if (item.peerName.toLowerCase().contains(needle) ||
          (item.preview?.toLowerCase().contains(needle) ?? false))
        item,
  ];
}
