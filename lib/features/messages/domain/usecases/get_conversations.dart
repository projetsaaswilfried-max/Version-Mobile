import '../../../../core/error/result.dart';
import '../entities/conversation_summary.dart';
import '../entities/messages_inbox.dart';
import '../repositories/messages_repository.dart';

class GetConversations {
  const GetConversations(this._repo);

  final MessagesRepository _repo;

  Future<Result<MessagesInbox>> call() async {
    final statusResult = await _repo.fetchSubscriptionStatus();
    switch (statusResult) {
      case Err<String>(:final failure):
        return Err(failure);
      case Ok<String>(:final value):
        if (value.trim().toUpperCase() == 'EXPIRED') {
          return const Ok(MessagesInbox(conversations: [], expired: true));
        }
        return _loadInbox();
    }
  }

  Future<Result<MessagesInbox>> _loadInbox() async {
    final result = await _repo.fetchConversations();
    switch (result) {
      case Err<List<ConversationSummary>>(:final failure):
        return Err(failure);
      case Ok<List<ConversationSummary>>(:final value):
        final sorted = [...value]
          ..sort((a, b) {
            final aAt = a.lastAt;
            final bAt = b.lastAt;
            if (aAt == null && bAt == null) return a.id.compareTo(b.id);
            if (aAt == null) return 1;
            if (bAt == null) return -1;
            return bAt.compareTo(aAt);
          });
        return Ok(MessagesInbox(conversations: sorted));
    }
  }
}
