import 'package:agapeo/features/feed/data/comments/comment_author_attach.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unwraps author when PostgREST returns a list', () {
    final row = normalizeCommentRow({
      'id': 'c1',
      'user_id': 'u1',
      'author': [
        {'first_name': 'Léa', 'last_name': 'Martin'},
      ],
    });
    expect(row['author'], isA<Map<String, dynamic>>());
    expect((row['author'] as Map)['first_name'], 'Léa');
  });

  test('collects user ids when the author embed is missing', () {
    final ids = missingCommentAuthorIds([
      {'id': 'c1', 'user_id': 'u1', 'content': 'Amen'},
      {
        'id': 'c2',
        'user_id': 'u2',
        'author': {'first_name': 'Paul'},
      },
    ]);
    expect(ids, ['u1']);
  });

  test('collects author ids that have a name but no verification status', () {
    final ids = missingCommentVerificationIds([
      {
        'id': 'c1',
        'user_id': 'u1',
        'author': {'id': 'u1', 'first_name': 'Léa'},
      },
      {
        'id': 'c2',
        'user_id': 'u2',
        'author': {
          'id': 'u2',
          'first_name': 'Paul',
          'photo_verification_status': 'VERIFIED',
        },
      },
    ]);
    expect(ids, ['u1']);
  });

  test('collects author ids that have a name but no photo', () {
    final ids = missingCommentAvatarIds([
      {
        'id': 'c1',
        'user_id': 'u1',
        'author': {'id': 'u1', 'first_name': 'Léa'},
      },
      {
        'id': 'c2',
        'user_id': 'u2',
        'author': {
          'id': 'u2',
          'first_name': 'Paul',
          'avatar_url': 'https://cdn.example/paul.jpg',
        },
      },
    ]);
    expect(ids, ['u1']);
  });

  test('treats storage paths as missing avatars', () {
    final ids = missingCommentAvatarIds([
      {
        'id': 'c1',
        'user_id': 'u1',
        'author': {
          'id': 'u1',
          'first_name': 'Léa',
          'profile_photos': [
            {'storage_path': 'u1/slot_0.jpg', 'is_primary': true},
          ],
        },
      },
    ]);
    expect(ids, ['u1']);
  });

  test('lists every comment author id', () {
    final ids = commentAuthorIds([
      {
        'id': 'c1',
        'user_id': 'u1',
        'author': {'first_name': 'Léa'},
      },
      {'id': 'c2', 'user_id': 'u2'},
    ]);
    expect(ids, ['u1', 'u2']);
  });

  test('overlays avatar_url onto an author that already has a name', () {
    final merged = mergeCommentAuthors(
      [
        {
          'id': 'c1',
          'user_id': 'u1',
          'author': {'id': 'u1', 'first_name': 'Léa'},
        },
      ],
      [
        {
          'id': 'u1',
          'first_name': 'Léa',
          'avatar_url': 'https://cdn.example/lea.jpg',
        },
      ],
    );
    expect(merged.single['author']['first_name'], 'Léa');
    expect(
      merged.single['author']['avatar_url'],
      'https://cdn.example/lea.jpg',
    );
  });

  test('merges profile_photos onto authors by profile id', () {
    final merged = mergeCommentPhotos(
      [
        {
          'id': 'c1',
          'user_id': 'u1',
          'author': {'id': 'u1', 'first_name': 'Léa'},
        },
      ],
      [
        {
          'profile_id': 'u1',
          'storage_path': 'u1/primary.jpg',
          'is_primary': true,
        },
      ],
    );
    expect(
      (merged.single['author']['profile_photos'] as List)
          .single['storage_path'],
      'u1/primary.jpg',
    );
  });

  test('merges profiles onto comments that have no author', () {
    final merged = mergeCommentAuthors(
      [
        {'id': 'c1', 'user_id': 'u1', 'content': 'Amen'},
      ],
      [
        {
          'id': 'u1',
          'first_name': 'Léa',
          'profile_photos': [
            {'storage_path': 'u1/primary.jpg', 'is_primary': true},
          ],
        },
      ],
    );
    expect(merged.single['author']['first_name'], 'Léa');
    expect(
      (merged.single['author']['profile_photos'] as List).first['storage_path'],
      'u1/primary.jpg',
    );
  });
}
