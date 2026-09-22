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

  test('flags incoming PENDING and uses web preview copy', () {
    final summary = ConversationSummaryModel.fromAssembled(
      currentUserId: 'me',
      conversation: {'id': 'c2', 'status': 'PENDING', 'initiated_by': 'them'},
      peer: {'first_name': 'Paul'},
      latestMessage: {'content': 'Hello'},
    );

    expect(summary!.preview, 'Souhaite discuter avec toi');
    expect(summary.isIncomingInvite, isTrue);
    expect(summary.status, 'PENDING');
  });

  test('incoming PENDING without last message still has preview and date', () {
    final summary = ConversationSummaryModel.fromAssembled(
      currentUserId: 'me',
      conversation: {
        'id': 'c-sarah',
        'status': 'PENDING',
        'initiated_by': 'them',
        'created_at': '2026-09-22T10:00:00Z',
      },
      peer: {'first_name': 'Sarah'},
    );

    expect(summary!.isIncomingInvite, isTrue);
    expect(summary.preview, 'Souhaite discuter avec toi');
    expect(summary.lastAt, DateTime.parse('2026-09-22T10:00:00Z'));
  });

  test('IMAGE without text uses Photo preview', () {
    final summary = ConversationSummaryModel.fromAssembled(
      currentUserId: 'me',
      conversation: {'id': 'c-img', 'status': 'ACCEPTED'},
      peer: {'first_name': 'Léa'},
      latestMessage: {'type': 'IMAGE', 'created_at': '2026-09-22T10:00:00Z'},
    );

    expect(summary!.preview, 'Photo');
  });

  test('IMAGE with filename content still previews as Photo', () {
    final summary = ConversationSummaryModel.fromAssembled(
      currentUserId: 'me',
      conversation: {'id': 'c-img-name', 'status': 'ACCEPTED'},
      peer: {'first_name': 'Léa'},
      latestMessage: {
        'type': 'IMAGE',
        'content': 'IMG_6170.PNG',
        'file_name': 'IMG_6170.PNG',
      },
    );

    expect(summary!.preview, 'Photo');
  });

  test('VOICE without text uses Audio preview', () {
    final summary = ConversationSummaryModel.fromAssembled(
      currentUserId: 'me',
      conversation: {'id': 'c-voice', 'status': 'ACCEPTED'},
      peer: {'first_name': 'Paul'},
      latestMessage: {'type': 'VOICE'},
    );

    expect(summary!.preview, 'Audio');
  });

  test('infers incoming PENDING from peer last message if initiator missing', () {
    final summary = ConversationSummaryModel.fromAssembled(
      currentUserId: 'me',
      conversation: {'id': 'c3', 'status': 'PENDING'},
      peer: {'first_name': 'Sarah'},
      latestMessage: {'content': 'Hi', 'sender_id': 'them'},
    );

    expect(summary!.isIncomingInvite, isTrue);
    expect(summary.preview, 'Souhaite discuter avec toi');
  });

  test('outgoing PENDING without message uses sent copy', () {
    final summary = ConversationSummaryModel.fromAssembled(
      currentUserId: 'me',
      conversation: {'id': 'c4', 'status': 'PENDING', 'initiated_by': 'me'},
      peer: {'first_name': 'Léa'},
    );

    expect(summary!.isIncomingInvite, isFalse);
    expect(summary.preview, 'Invitation envoyée');
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
