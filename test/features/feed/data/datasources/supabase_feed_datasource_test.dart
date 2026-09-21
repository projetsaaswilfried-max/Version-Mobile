import 'package:agapeo/features/feed/data/datasources/supabase_feed_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('feedMediaExtension', () {
    test('uses the real file extension', () {
      expect(
        feedMediaExtension('/tmp/video.mov', fallback: 'mp4'),
        'mov',
      );
      expect(
        feedMediaExtension('/tmp/clip.webm', fallback: 'mp4'),
        'webm',
      );
    });

    test('falls back when there is no plausible extension', () {
      expect(
        feedMediaExtension('/tmp/no-extension', fallback: 'mp4'),
        'mp4',
      );
      // Un identifiant contenant un point ne doit pas être pris pour une
      // extension (ex. un UUID tronqué).
      expect(
        feedMediaExtension('/tmp/8f14e45fceea167a5a36dedd4bea2543.tmp.a1b2c3d4e5', fallback: 'jpg'),
        'jpg',
      );
    });
  });

  group('feedVideoContentType', () {
    test('maps known extensions to their real content type', () {
      expect(feedVideoContentType('mov'), 'video/quicktime');
      expect(feedVideoContentType('webm'), 'video/webm');
      expect(feedVideoContentType('3gp'), 'video/3gpp');
      expect(feedVideoContentType('m4v'), 'video/x-m4v');
      expect(feedVideoContentType('mkv'), 'video/x-matroska');
    });

    test('defaults to video/mp4 for mp4 and unknown extensions', () {
      expect(feedVideoContentType('mp4'), 'video/mp4');
      expect(feedVideoContentType('xyz'), 'video/mp4');
    });
  });
}
