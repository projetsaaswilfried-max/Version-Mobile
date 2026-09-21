import '../../../../core/error/result.dart';
import '../entities/message.dart';
import '../repositories/messages_repository.dart';

class GetMessages {
  const GetMessages(this._repo);

  final MessagesRepository _repo;

  Future<Result<List<Message>>> call(String conversationId) =>
      _repo.fetchMessages(conversationId);
}
