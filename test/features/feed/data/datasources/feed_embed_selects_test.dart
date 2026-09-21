import 'package:agapeo/features/feed/data/datasources/feed_embed_selects.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('post embeds never use an ambiguous profiles relationship', () {
    for (final select in FeedEmbedSelects.posts) {
      if (select.contains('profiles')) {
        expect(select.contains('profiles!'), isTrue, reason: select);
      }
    }
  });

  test('comment embeds never use an ambiguous profiles relationship', () {
    for (final select in FeedEmbedSelects.comments) {
      if (select.contains('profiles')) {
        expect(select.contains('profiles!'), isTrue, reason: select);
      }
    }
  });

  test('comment profile embeds include avatar_url and verification', () {
    for (final select in FeedEmbedSelects.comments) {
      if (select.contains('author:profiles')) {
        expect(select.contains('avatar_url'), isTrue, reason: select);
        expect(
          select.contains('photo_verification_status'),
          isTrue,
          reason: select,
        );
      }
    }
  });

  test(
    'comment selects keep an author embed without nested photos before dropping profiles',
    () {
      final withoutPhotos = FeedEmbedSelects.comments.indexWhere(
        (select) =>
            select.contains('author:profiles') &&
            !select.contains('profile_photos'),
      );
      final withoutProfiles = FeedEmbedSelects.comments.indexWhere(
        (select) => !select.contains('profiles'),
      );
      expect(withoutPhotos, isNonNegative);
      expect(withoutProfiles, isNonNegative);
      expect(withoutPhotos, lessThan(withoutProfiles));
    },
  );
}
