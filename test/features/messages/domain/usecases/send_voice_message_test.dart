import 'dart:io';

import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/messages/domain/usecases/send_voice_message.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/messages_test_fakes.dart';

void main() {
  test('SendVoiceMessage refuse une note trop courte', () async {
    final file = await File(
      '${Directory.systemTemp.path}/agapeo-voice-test-short.m4a',
    ).create();
    addTearDown(() => file.delete());
    final repo = FakeMessagesRepository();
    final result = await SendVoiceMessage(repo)(
      conversationId: 'c1',
      localPath: file.path,
      durationSeconds: 0,
    );
    expect(result, isA<Err>());
    expect(repo.sendVoiceCalls, 0);
  });

  test('SendVoiceMessage refuse un fichier manquant', () async {
    final repo = FakeMessagesRepository();
    final result = await SendVoiceMessage(repo)(
      conversationId: 'c1',
      localPath: '${Directory.systemTemp.path}/missing-voice.m4a',
      durationSeconds: 4,
    );
    expect(result, isA<Err>());
    expect(repo.sendVoiceCalls, 0);
  });

  test('SendVoiceMessage forward path et durée', () async {
    final file = await File(
      '${Directory.systemTemp.path}/agapeo-voice-test-ok.m4a',
    ).create();
    addTearDown(() => file.delete());
    final repo = FakeMessagesRepository();
    final result = await SendVoiceMessage(repo)(
      conversationId: 'c1',
      localPath: file.path,
      durationSeconds: 6,
    );
    expect(result, isA<Ok>());
    expect(repo.sendVoiceCalls, 1);
    expect(repo.lastSendVoicePath, file.path);
    expect(repo.lastSendVoiceDuration, 6);
  });
}
