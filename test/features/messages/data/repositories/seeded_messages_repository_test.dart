import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/messages/data/repositories/seeded_messages_repository.dart';
import 'package:agapeo/features/messages/domain/entities/conversation_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 9, 19, 10);

  test('seed couvre ACCEPTED, invitations PENDING et système', () {
    final items = SeededMessagesRepository.seed(now: now);

    expect(items.map((c) => c.id), [
      'fake-accepted-1',
      'fake-pending-1',
      'fake-pending-out',
      'fake-system-1',
      'fake-accepted-2',
    ]);
    expect(items[0].unreadCount, greaterThan(0));
    expect(items[1].status, 'PENDING');
    expect(items[1].isIncomingInvite, isTrue);
    expect(items[2].status, 'PENDING');
    expect(items[2].isIncomingInvite, isFalse);
    expect(items[3].isSystem, isTrue);
    expect(items[3].peerName, 'Agapeo');
    expect(items[4].unreadCount, 0);
  });

  test('fetchConversations et abo FREE', () async {
    final repo = SeededMessagesRepository(now: now);

    final status = await repo.fetchSubscriptionStatus();
    final conversations = await repo.fetchConversations();

    expect(status, isA<Ok<String>>());
    expect((status as Ok<String>).value, 'FREE');
    expect(conversations, isA<Ok<List<ConversationSummary>>>());
    expect(
      (conversations as Ok<List<ConversationSummary>>).value,
      hasLength(5),
    );
  });
}
