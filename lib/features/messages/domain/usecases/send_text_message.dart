import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/message.dart';
import '../repositories/messages_repository.dart';

class SendTextMessage {
  const SendTextMessage(this._repo);

  final MessagesRepository _repo;

  Future<Result<Message>> call({
    required String conversationId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const Err(ValidationFailure('Message vide'));
    }
    return _repo.sendText(conversationId: conversationId, text: trimmed);
  }
}
