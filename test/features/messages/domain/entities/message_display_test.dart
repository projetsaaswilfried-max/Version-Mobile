import 'package:agapeo/features/messages/domain/entities/message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deleted → Message supprimé', () {
    final m = Message(
      id: '1',
      conversationId: 'c',
      type: MessageType.text,
      createdAt: DateTime.utc(2026, 9, 19),
      content: 'secret',
      deleted: true,
    );
    expect(messageDisplayText(m), 'Message supprimé');
  });

  test('texte normal conserve le content', () {
    final m = Message(
      id: '2',
      conversationId: 'c',
      type: MessageType.text,
      createdAt: DateTime.utc(2026, 9, 19),
      content: 'Bonjour',
    );
    expect(messageDisplayText(m), 'Bonjour');
  });
}
