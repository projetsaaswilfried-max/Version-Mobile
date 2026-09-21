import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/messages/data/repositories/seeded_messages_repository.dart';
import 'package:agapeo/features/messages/domain/entities/conversation_match.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('propose → cancel sur Léa', () async {
    final repo = SeededMessagesRepository();
    final before = await repo.fetchMatch('fake-accepted-1');
    expect((before as Ok).value, ConversationMatch.none);

    final proposed = await repo.proposeMatch('fake-accepted-1');
    expect(
      (proposed as Ok).value.status,
      ConversationMatchStatus.pending,
    );

    final cancelled = await repo.cancelMatch('fake-accepted-1');
    expect((cancelled as Ok).value, ConversationMatch.none);
  });

  test('Camille démarre en pending incoming', () async {
    final repo = SeededMessagesRepository();
    final match = await repo.fetchMatch('fake-accepted-2');
    final value = (match as Ok<ConversationMatch>).value;
    expect(value.status, ConversationMatchStatus.pending);
    expect(value.isIncoming, isTrue);
  });
}
