import 'package:agapeo/features/feed/domain/comments/comment_threads.dart';
import 'package:agapeo/features/feed/domain/entities/post_comment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nests one-level replies under their parent', () {
    const parent = PostComment(id: 'c1', body: 'Amen', authorName: 'Léa');
    const reply = PostComment(
      id: 'c2',
      body: 'Oui',
      authorName: 'Paul',
      parentId: 'c1',
    );
    const other = PostComment(id: 'c3', body: 'Merci', authorName: 'Eva');
    final threads = groupCommentThreads(const [parent, reply, other]);
    expect(threads, hasLength(2));
    expect(threads.first.parent.id, 'c1');
    expect(threads.first.replies.single.id, 'c2');
    expect(threads.last.parent.id, 'c3');
    expect(threads.last.replies, isEmpty);
  });

  test('lifts nested replies onto the root comment', () {
    const root = PostComment(id: 'c1', body: 'Amen', authorName: 'Léa');
    const reply = PostComment(
      id: 'c2',
      body: 'Oui',
      authorName: 'Paul',
      parentId: 'c1',
    );
    const nested = PostComment(
      id: 'c3',
      body: 'Exact',
      authorName: 'Eva',
      parentId: 'c2',
    );
    final threads = groupCommentThreads(const [root, reply, nested]);
    expect(threads, hasLength(1));
    expect(threads.single.replies.map((c) => c.id), ['c2', 'c3']);
  });

  test(
    'a reply-to-a-reply always comes after its parent, even if the input '
    'list has it earlier (e.g. equal/out-of-order created_at)',
    () {
      const root = PostComment(id: 'c1', body: 'Svp', authorName: 'Ruth');
      const reply = PostComment(
        id: 'c2',
        body: 'Oui Mme Ruth...',
        authorName: 'Équipe Agapeo',
        parentId: 'c1',
      );
      const replyToReply = PostComment(
        id: 'c3',
        body: 'Merci',
        authorName: 'Ruth',
        parentId: 'c2',
      );
      // c3 arrives before its own parent c2 in the input list.
      final threads = groupCommentThreads(const [root, replyToReply, reply]);
      expect(threads.single.replies.map((c) => c.id), ['c2', 'c3']);
    },
  );

  test('replyTarget walks nested replies up to the root', () {
    const root = PostComment(id: 'c1', body: 'Amen', authorName: 'Léa');
    const reply = PostComment(
      id: 'c2',
      body: 'Oui',
      authorName: 'Paul',
      parentId: 'c1',
    );
    expect(replyTarget(reply, const [root, reply]).id, 'c1');
    expect(replyTarget(root, const [root, reply]).id, 'c1');
  });

  test('hides every reply until the thread is expanded', () {
    expect(visibleReplyCount(0), 0);
    expect(visibleReplyCount(2), 0);
    expect(visibleReplyCount(3), 0);
    expect(visibleReplyCount(5, expanded: true), 5);
  });

  test('toggle label matches the web thread copy', () {
    expect(
      repliesToggleLabel(count: 1, expanded: false),
      'Voir 1 réponse',
    );
    expect(
      repliesToggleLabel(count: 2, expanded: false),
      'Voir les 2 réponses',
    );
    expect(
      repliesToggleLabel(count: 3, expanded: true),
      'Masquer les réponses',
    );
  });
}
