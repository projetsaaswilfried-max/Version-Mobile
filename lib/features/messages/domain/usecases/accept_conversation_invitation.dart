import '../../../../core/error/result.dart';
import '../repositories/messages_repository.dart';

class AcceptConversationInvitation {
  const AcceptConversationInvitation(this._repo);

  final MessagesRepository _repo;

  Future<Result<void>> call(String conversationId) =>
      _repo.acceptInvitation(conversationId);
}
