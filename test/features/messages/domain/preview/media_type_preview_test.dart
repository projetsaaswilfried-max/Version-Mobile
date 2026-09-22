import 'package:agapeo/features/messages/domain/preview/media_type_preview.dart';
import 'package:agapeo/features/messages/presentation/thread/voice_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('media preview labels', () {
    expect(mediaTypePreviewLabel('IMAGE'), 'Photo');
    expect(mediaTypePreviewLabel('voice'), 'Audio');
    expect(mediaTypePreviewLabel('AUDIO'), 'Audio');
    expect(mediaTypePreviewLabel('VIDEO'), 'Vidéo');
    expect(mediaTypePreviewLabel('TEXT'), isNull);
  });

  test('list preview prefers type over filename', () {
    expect(
      conversationLastMessagePreview(
        type: 'IMAGE',
        content: 'IMG_6170.PNG',
        fileName: 'IMG_6170.PNG',
      ),
      'Photo',
    );
    expect(
      conversationLastMessagePreview(type: 'VOICE', content: 'note.m4a'),
      'Audio',
    );
    expect(
      conversationLastMessagePreview(type: 'TEXT', content: 'Hello'),
      'Hello',
    );
    expect(
      conversationLastMessagePreview(type: 'TEXT', content: 'IMG_6170.PNG'),
      'Photo',
    );
  });

  test('voice clock pads seconds', () {
    expect(formatVoiceClock(42), '0:42');
    expect(formatVoiceClock(75), '1:15');
    expect(formatVoiceClock(-1), '0:00');
  });
}
