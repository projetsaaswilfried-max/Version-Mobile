import 'package:agapeo/features/messages/data/models/message_attachment_merge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('merges signed url, file name and duration', () {
    final message = <String, dynamic>{'id': 'm1', 'type': 'VOICE'};
    mergeAttachmentIntoMessage(
      message,
      attachment: {
        'file_name': 'note.m4a',
        'duration_seconds': 12,
        'mime_type': 'audio/mp4',
      },
      resolvedUrl: 'https://signed.example/note.m4a',
    );

    expect(message['media_url'], 'https://signed.example/note.m4a');
    expect(message['file_name'], 'note.m4a');
    expect(message['duration_seconds'], 12);
    expect(message['mime_type'], 'audio/mp4');
    expect(message['type'], 'VOICE');
  });

  test('object path prefers storage_path even if url is http', () {
    expect(
      attachmentObjectPath({
        'url': 'https://cdn.example/object/public/message-attachments/user/a.jpg',
        'storage_path': 'user/a.jpg',
      }),
      'user/a.jpg',
    );
    expect(
      attachmentHttpUrl({
        'url': 'https://cdn.example/object/public/message-attachments/user/a.jpg',
      }),
      isNull,
    );
    expect(
      attachmentHttpUrl({
        'url': 'https://cdn.example/object/sign/message-attachments/user/a.jpg?token=1',
      }),
      'https://cdn.example/object/sign/message-attachments/user/a.jpg?token=1',
    );
    expect(
      attachmentObjectPath({
        'storage_path': 'message-attachments/user/voice.m4a',
      }),
      'user/voice.m4a',
    );
    expect(
      attachmentObjectPath({'storage_path': 'user/voice.m4a'}),
      'user/voice.m4a',
    );
    expect(
      attachmentObjectPath({
        'url':
            'https://proj.supabase.co/storage/v1/object/authenticated/message-attachments/uid/note.webm',
      }),
      'uid/note.webm',
    );
  });
}
