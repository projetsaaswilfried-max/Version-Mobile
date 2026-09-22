import 'package:agapeo/features/messages/data/models/message_model.dart';
import 'package:agapeo/features/messages/domain/entities/message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromRow TEXT moi + soft-delete', () {
    final message = MessageModel.fromRow(
      row: {
        'id': '1',
        'conversation_id': 'c',
        'content': 'x',
        'sender_id': 'me',
        'type': 'TEXT',
        'created_at': '2026-09-19T10:00:00Z',
        'deleted_at': '2026-09-19T11:00:00Z',
      },
      currentUserId: 'me',
    )!;
    expect(message.senderIsMe, isTrue);
    expect(message.deleted, isTrue);
    expect(message.type, MessageType.text);
  });

  test('fromRow IMAGE', () {
    final message = MessageModel.fromRow(
      row: {
        'id': '2',
        'conversation_id': 'c',
        'type': 'IMAGE',
        'sender_id': 'other',
        'created_at': '2026-09-19T10:00:00Z',
        'media_url': 'https://example.com/a.jpg',
      },
      currentUserId: 'me',
    )!;
    expect(message.type, MessageType.image);
    expect(message.senderIsMe, isFalse);
    expect(message.mediaUrl, 'https://example.com/a.jpg');
  });

  test('fromRow VOICE with duration and AUDIO alias', () {
    final voice = MessageModel.fromRow(
      row: {
        'id': '3',
        'conversation_id': 'c',
        'type': 'VOICE',
        'sender_id': 'other',
        'created_at': '2026-09-19T10:00:00Z',
        'media_url': 'https://example.com/a.m4a',
        'duration_seconds': 12,
      },
      currentUserId: 'me',
    )!;
    expect(voice.type, MessageType.voice);
    expect(voice.mediaUrl, 'https://example.com/a.m4a');
    expect(voice.durationSeconds, 12);

    final audio = MessageModel.fromRow(
      row: {
        'id': '4',
        'conversation_id': 'c',
        'type': 'AUDIO',
        'sender_id': 'me',
        'created_at': '2026-09-19T10:00:00Z',
      },
      currentUserId: 'me',
    )!;
    expect(audio.type, MessageType.voice);
    expect(audio.senderIsMe, isTrue);
  });
}
