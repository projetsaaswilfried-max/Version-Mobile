import 'dart:io';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/message.dart';
import '../repositories/messages_repository.dart';

class SendImageMessage {
  const SendImageMessage(this._repo);

  final MessagesRepository _repo;

  Future<Result<Message>> call({
    required String conversationId,
    required String localPath,
  }) async {
    if (!File(localPath).existsSync()) {
      return const Err(ValidationFailure('Photo introuvable.'));
    }
    return _repo.sendImage(conversationId: conversationId, localPath: localPath);
  }
}
