import '../../../../core/error/result.dart';
import '../repositories/messages_repository.dart';

class DeclineConversationInvitation {
  const DeclineConversationInvitation(this._repo);

  final MessagesRepository _repo;

  Future<Result<void>> call(String conversationId) =>
      _repo.declineInvitation(conversationId);
}
