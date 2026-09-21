import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/messages/domain/usecases/send_text_message.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/messages_test_fakes.dart';

void main() {
  test('SendTextMessage refuse texte vide', () async {
    final repo = FakeMessagesRepository();
    final result = await SendTextMessage(repo)(
      conversationId: 'c',
      text: '  ',
    );
    expect(result, isA<Err>());
    expect(repo.sendTextCalls, 0);
  });

  test('SendTextMessage forward texte trimé', () async {
    final repo = FakeMessagesRepository();
    final result = await SendTextMessage(repo)(
      conversationId: 'c',
      text: '  Salut  ',
    );
    expect(result, isA<Ok>());
    expect(repo.sendTextCalls, 1);
    expect(repo.lastSendText, 'Salut');
  });
}
