import 'package:agapeo/features/feed/domain/mapping/youtube.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses watch, short and embed URLs', () {
    expect(
      youtubeVideoId('https://www.youtube.com/watch?v=abcdefghijk'),
      'abcdefghijk',
    );
    expect(youtubeVideoId('https://youtu.be/abcdefghijk'), 'abcdefghijk');
    expect(
      youtubeVideoId('https://www.youtube.com/embed/abcdefghijk'),
      'abcdefghijk',
    );
    expect(
      youtubeVideoId('https://www.youtube.com/shorts/abcdefghijk'),
      'abcdefghijk',
    );
    expect(youtubeVideoId('abcdefghijk'), 'abcdefghijk');
  });

  test('builds watch, thumbnail and embed URLs', () {
    expect(
      youtubeWatchUrl('abcdefghijk'),
      'https://www.youtube.com/watch?v=abcdefghijk',
    );
    expect(
      youtubeThumbnailUrl('abcdefghijk'),
      'https://img.youtube.com/vi/abcdefghijk/hqdefault.jpg',
    );
    expect(
      youtubeEmbedUrl('abcdefghijk'),
      'https://www.youtube-nocookie.com/embed/abcdefghijk?playsinline=1&rel=0',
    );
  });
}
