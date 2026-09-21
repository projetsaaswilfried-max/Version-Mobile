import 'package:agapeo/features/messages/data/models/conversation_summary_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses peer name, truncated preview and unread', () {
    final summary = ConversationSummaryModel.fromAssembled(
      currentUserId: 'me',
      conversation: {
        'id': 'c1',
        'status': 'ACCEPTED',
        'is_system_broadcast': false,
        'last_message_at': '2026-09-19T10:00:00Z',
        'initiated_by': 'me',
      },
      peer: {
        'id': 'them',
        'first_name': 'Léa',
        'last_name': 'Martin',
        'photo_url': 'https://cdn.example/lea.jpg',
      },
      latestMessage: {
        'content': 'A' * 90,
        'created_at': '2026-09-19T09:00:00Z',
        'sender_id': 'them',
      },
      lastReadAt: DateTime.utc(2026, 9, 19, 8),
      incomingCreatedAts: [
        DateTime.utc(2026, 9, 19, 7),
        DateTime.utc(2026, 9, 19, 9),
      ],
    );

    expect(summary, isNotNull);
    expect(summary!.peerName, 'Léa Martin');
    expect(summary.peerPhotoUrl, 'https://cdn.example/lea.jpg');
    expect(summary.preview!.length, 83);
    expect(summary.preview!.endsWith('...'), isTrue);
    expect(summary.unreadCount, 1);
    expect(summary.isIncomingInvite, isFalse);
    expect(summary.isSystem, isFalse);
  });

  test('flags incoming PENDING', () {
    final summary = ConversationSummaryModel.fromAssembled(
      currentUserId: 'me',
      conversation: {'id': 'c2', 'status': 'PENDING', 'initiated_by': 'them'},
      peer: {'first_name': 'Paul'},
      latestMessage: {'content': 'Hello'},
    );

    expect(summary!.preview, 'Hello');
    expect(summary.isIncomingInvite, isTrue);
    expect(summary.status, 'PENDING');
  });

  test('system broadcast uses Agapeo name', () {
    final summary = ConversationSummaryModel.fromAssembled(
      currentUserId: 'me',
      conversation: {
        'id': 'sys',
        'status': 'ACCEPTED',
        'is_system_broadcast': true,
      },
      peer: {'first_name': 'Ignored'},
    );

    expect(summary!.peerName, 'Agapeo');
    expect(summary.isSystem, isTrue);
    expect(summary.peerPhotoUrl, isNull);
  });

  test('skips DECLINED conversations', () {
    expect(
      ConversationSummaryModel.fromAssembled(
        currentUserId: 'me',
        conversation: {'id': 'x', 'status': 'DECLINED'},
      ),
      isNull,
    );
  });
}
