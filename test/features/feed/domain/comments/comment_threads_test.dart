import 'package:agapeo/features/feed/domain/comments/comment_threads.dart';
import 'package:agapeo/features/feed/domain/entities/post_comment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nests one-level replies under their parent', () {
    final parent = PostComment(
      id: 'c1',
      body: 'Amen',
      authorName: 'Léa',
      createdAt: DateTime.utc(2026, 1, 1, 10),
    );
    final reply = PostComment(
      id: 'c2',
      body: 'Oui',
      authorName: 'Paul',
      parentId: 'c1',
      createdAt: DateTime.utc(2026, 1, 1, 11),
    );
    final other = PostComment(
      id: 'c3',
      body: 'Merci',
      authorName: 'Eva',
      createdAt: DateTime.utc(2026, 1, 1, 12),
    );
    final threads = groupCommentThreads([parent, reply, other]);
    expect(threads, hasLength(2));
    // Racines : plus récent en premier - c3 (12h) avant c1 (10h).
    expect(threads.first.parent.id, 'c3');
    expect(threads.first.replies, isEmpty);
    expect(threads.last.parent.id, 'c1');
    expect(threads.last.replies.single.id, 'c2');
  });

  test('lifts nested replies onto the root comment', () {
    final root = PostComment(
      id: 'c1',
      body: 'Amen',
      authorName: 'Léa',
      createdAt: DateTime.utc(2026, 1, 1, 10),
    );
    final reply = PostComment(
      id: 'c2',
      body: 'Oui',
      authorName: 'Paul',
      parentId: 'c1',
      createdAt: DateTime.utc(2026, 1, 1, 11),
    );
    final nested = PostComment(
      id: 'c3',
      body: 'Exact',
      authorName: 'Eva',
      parentId: 'c2',
      createdAt: DateTime.utc(2026, 1, 1, 12),
    );
    final threads = groupCommentThreads([root, reply, nested]);
    expect(threads, hasLength(1));
    expect(threads.single.replies.map((c) => c.id), ['c2', 'c3']);
  });

  test(
    'a reply-to-a-reply always comes after its parent, even if the input '
    'list has it earlier or its created_at is not strictly later',
    () {
      final root = PostComment(
        id: 'c1',
        body: 'Svp',
        authorName: 'Ruth',
        createdAt: DateTime.utc(2026, 1, 1, 10),
      );
      final reply = PostComment(
        id: 'c2',
        body: 'Oui Mme Ruth...',
        authorName: 'Équipe Agapeo',
        parentId: 'c1',
        createdAt: DateTime.utc(2026, 1, 1, 11),
      );
      final replyToReply = PostComment(
        id: 'c3',
        body: 'Merci',
        authorName: 'Ruth',
        parentId: 'c2',
        createdAt: DateTime.utc(2026, 1, 1, 12),
      );
      // c3 arrives before its own parent c2 in the input list.
      final threads = groupCommentThreads([root, replyToReply, reply]);
      expect(threads.single.replies.map((c) => c.id), ['c2', 'c3']);
    },
  );

  test(
    'roots newest-first, replies (any depth) oldest-first, like the web '
    '- fixes a real thread where a same-parent reply posted later showed '
    'before the reply it was thanking',
    () {
      final rootOld = PostComment(
        id: 'root-old',
        body: 'Svp revoyez le site',
        authorName: 'Ruth',
        createdAt: DateTime.utc(2026, 9, 26, 10, 48),
      );
      final teamReply = PostComment(
        id: 'team-reply',
        body: 'Oui Mme Ruth...',
        authorName: 'Équipe Agapeo',
        parentId: 'root-old',
        createdAt: DateTime.utc(2026, 9, 26, 21, 14),
      );
      final thanks = PostComment(
        id: 'thanks',
        body: 'Merci',
        authorName: 'Ruth',
        parentId: 'root-old',
        // Posted *after* teamReply, must still display after it.
        createdAt: DateTime.utc(2026, 9, 27, 0, 3),
      );
      final rootNew = PostComment(
        id: 'root-new',
        body: 'Salut, je viens de payer',
        authorName: 'Mohamed',
        createdAt: DateTime.utc(2026, 9, 27, 5),
      );
      final threads = groupCommentThreads([
        rootOld,
        teamReply,
        thanks,
        rootNew,
      ]);
      expect(threads.map((t) => t.parent.id), ['root-new', 'root-old']);
      expect(
        threads.last.replies.map((c) => c.id),
        ['team-reply', 'thanks'],
      );
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
