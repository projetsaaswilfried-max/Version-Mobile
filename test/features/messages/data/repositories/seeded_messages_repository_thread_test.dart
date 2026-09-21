import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/messages/data/repositories/seeded_messages_repository.dart';
import 'package:agapeo/features/messages/domain/entities/conversation_summary.dart';
import 'package:agapeo/features/messages/domain/entities/message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fetchMessages trié chrono + sendText append', () async {
    final repo = SeededMessagesRepository();
    final before = await repo.fetchMessages('fake-accepted-1');
    final list = (before as Ok<List<Message>>).value;
    expect(list, isNotEmpty);
    expect(!list.first.createdAt.isAfter(list.last.createdAt), isTrue);

    final sent = await repo.sendText(
      conversationId: 'fake-accepted-1',
      text: 'Salut',
    );
    expect(sent, isA<Ok<Message>>());
    final after =
        (await repo.fetchMessages('fake-accepted-1') as Ok<List<Message>>)
            .value;
    expect(after.last.content, 'Salut');
    expect(after.last.senderIsMe, isTrue);
  });

  test('acceptInvitation passe en ACCEPTED ; decline retire la conv', () async {
    final repo = SeededMessagesRepository();
    await repo.acceptInvitation('fake-pending-1');
    final conv =
        (await repo.fetchConversation('fake-pending-1')
                as Ok<ConversationSummary?>)
            .value!;
    expect(conv.status, 'ACCEPTED');
    expect(conv.isIncomingInvite, isFalse);

    final repo2 = SeededMessagesRepository();
    await repo2.declineInvitation('fake-pending-1');
    final gone =
        (await repo2.fetchConversation('fake-pending-1')
                as Ok<ConversationSummary?>)
            .value;
    expect(gone, isNull);
    final list =
        (await repo2.fetchConversations() as Ok<List<ConversationSummary>>)
            .value;
    expect(list.any((c) => c.id == 'fake-pending-1'), isFalse);
  });

  test('seed inclut PENDING sortant', () {
    final items = SeededMessagesRepository.seedConversations();
    expect(items.any((c) => c.id == 'fake-pending-out'), isTrue);
  });
}
