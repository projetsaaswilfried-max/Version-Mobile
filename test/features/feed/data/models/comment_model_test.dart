import 'package:agapeo/features/feed/data/models/comment_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses content and nested author name', () {
    final comment = CommentModel.fromJson({
      'id': 'c1',
      'content': 'Amen',
      'created_at': '2026-01-02T10:00:00Z',
      'author': {'first_name': 'Léa', 'last_name': 'Martin'},
    });
    expect(comment, isNotNull);
    expect(comment!.id, 'c1');
    expect(comment.body, 'Amen');
    expect(comment.authorName, 'Léa Martin');
    expect(comment.createdAt, DateTime.parse('2026-01-02T10:00:00Z'));
  });

  test('falls back to body when content is missing', () {
    final comment = CommentModel.fromJson({
      'id': 'c2',
      'body': 'Merci',
      'profiles': {'first_name': 'Paul'},
    });
    expect(comment!.body, 'Merci');
    expect(comment.authorName, 'Paul');
  });

  test('accepts numeric ids from PostgREST', () {
    final comment = CommentModel.fromJson({'id': 42, 'content': 'Amen'});
    expect(comment!.id, '42');
    expect(comment.body, 'Amen');
  });

  test('reads parent id and avatar from nested photos', () {
    final comment = CommentModel.fromJson({
      'id': 'c3',
      'content': 'Oui',
      'parent_comment_id': 'c1',
      'author': {
        'first_name': 'Paul',
        'avatar_url': 'https://cdn.example/paul.jpg',
      },
    });
    expect(comment!.parentId, 'c1');
    expect(comment.authorAvatarUrl, 'https://cdn.example/paul.jpg');
    expect(comment.isReply, isTrue);
  });

  test('keeps http avatars and ignores storage paths', () {
    final withUrl = CommentModel.fromJson({
      'id': 'c5',
      'content': 'Amen',
      'author': {
        'first_name': 'Léa',
        'avatar_url': 'https://cdn.example/lea.jpg',
      },
    });
    expect(withUrl!.authorAvatarUrl, 'https://cdn.example/lea.jpg');

    final withPath = CommentModel.fromJson({
      'id': 'c6',
      'content': 'Amen',
      'author': {
        'first_name': 'Léa',
        'profile_photos': [
          {'selfie_storage_path': 'u1/slot_0.jpg', 'is_primary': true},
        ],
      },
    });
    expect(withPath!.authorAvatarUrl, isNull);
  });

  test('reads verification from nested author', () {
    final verified = CommentModel.fromJson({
      'id': 'c7',
      'content': 'Amen',
      'author': {'first_name': 'Léa', 'photo_verification_status': 'VERIFIED'},
    });
    expect(verified!.isVerified, isTrue);

    final pending = CommentModel.fromJson({
      'id': 'c8',
      'content': 'Amen',
      'author': {'first_name': 'Paul', 'photo_verification_status': 'PENDING'},
    });
    expect(pending!.isVerified, isFalse);
  });

  test('reads author when PostgREST nests a one-item list', () {
    final comment = CommentModel.fromJson({
      'id': 'c4',
      'content': 'Amen',
      'author': [
        {'first_name': 'Léa', 'last_name': 'Martin'},
      ],
    });
    expect(comment!.authorName, 'Léa Martin');
  });
}
