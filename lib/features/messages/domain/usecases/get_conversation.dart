import '../../../../core/error/result.dart';
import '../entities/conversation_summary.dart';
import '../repositories/messages_repository.dart';

class GetConversation {
  const GetConversation(this._repo);

  final MessagesRepository _repo;

  Future<Result<ConversationSummary?>> call(String id) =>
      _repo.fetchConversation(id);
}
