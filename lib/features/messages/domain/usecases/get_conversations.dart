import '../../../../core/error/result.dart';
import '../entities/conversation_summary.dart';
import '../entities/messages_inbox.dart';
import '../repositories/messages_repository.dart';

class GetConversations {
  const GetConversations(this._repo);

  final MessagesRepository _repo;

  /// EXPIRED voit ses conversations existantes comme FREE (D42) - seul
  /// l'envoi d'un nouveau message reste bloqué (composer, isPremiumActive).
  Future<Result<MessagesInbox>> call() async {
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
