import 'dart:io';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/message.dart';
import '../repositories/messages_repository.dart';
import '../voice/voice_note_recorder.dart';

class SendVoiceMessage {
  const SendVoiceMessage(this._repo);

  final MessagesRepository _repo;

  Future<Result<Message>> call({
    required String conversationId,
    required String localPath,
    required int durationSeconds,
  }) async {
    if (durationSeconds < kMinVoiceNoteSeconds) {
      return const Err(ValidationFailure('Note vocale trop courte.'));
    }
    if (!File(localPath).existsSync()) {
      return const Err(ValidationFailure('Note vocale introuvable.'));
    }
    return _repo.sendVoice(
      conversationId: conversationId,
      localPath: localPath,
      durationSeconds: durationSeconds,
    );
  }
}
