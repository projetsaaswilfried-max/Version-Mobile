import 'package:agapeo/features/feed/domain/entities/post.dart';
import 'package:agapeo/features/feed/domain/entities/post_author.dart';
import 'package:agapeo/features/feed/domain/entities/post_media_type.dart';
import 'package:agapeo/features/feed/domain/share/post_share_text.dart';
import 'package:flutter_test/flutter_test.dart';

Post _post({String? title, String body = 'Corps'}) {
  return Post(
    id: '1',
    author: const PostAuthor(displayName: 'Agapeo'),
    title: title,
    body: body,
    mediaType: PostMediaType.textOnly,
    isPinned: false,
    likeCount: 0,
    commentCount: 0,
    shareCount: 0,
  );
}

void main() {
  test('prefers title over body', () {
    expect(
      postShareText(_post(title: 'Enseignement', body: 'Long corps')),
      'Enseignement',
    );
  });

  test('falls back to body when title is blank', () {
    expect(
      postShareText(_post(title: '  ', body: 'Un témoignage')),
      'Un témoignage',
    );
  });

  test('does not invent a web url', () {
    expect(postShareUrl(_post()), isNull);
  });
}
