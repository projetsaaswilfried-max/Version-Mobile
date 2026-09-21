import 'dart:async';

import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/feed/di/feed_providers.dart';
import 'package:agapeo/features/feed/domain/entities/feed_page.dart';
import 'package:agapeo/features/feed/domain/entities/post.dart';
import 'package:agapeo/features/feed/domain/entities/post_comment.dart';
import 'package:agapeo/features/feed/domain/entities/post_media_type.dart';
import 'package:agapeo/features/feed/presentation/pages/post_detail_page.dart';
import 'package:agapeo/features/feed/presentation/share/post_share_sheet.dart';
import 'package:agapeo/features/feed/presentation/widgets/feed_comments_skeleton.dart';
import 'package:agapeo/features/feed/presentation/widgets/feed_gallery_view.dart';
import 'package:agapeo/features/feed/presentation/widgets/feed_post_actions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../helpers/feed_test_fakes.dart';

class _FakeShareSheet implements PostShareSheet {
  final texts = <String>[];

  @override
  Future<bool> share(String text) async {
    texts.add(text);
    return true;
  }
}

Widget _detail(Post post, {FakeFeedRepository? repo, PostShareSheet? sheet}) {
  final feedRepo = repo ?? FakeFeedRepository();
  feedRepo.result = Ok(FeedPage(items: [post], hasMore: false));
  return ProviderScope(
    overrides: [
      feedRepositoryProvider.overrideWithValue(feedRepo),
      if (sheet != null) postShareSheetProvider.overrideWithValue(sheet),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: PostDetailPage(post: post),
    ),
  );
}

void main() {
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });
  testWidgets('shows full body without truncation and ignored actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _detail(
        fakePost(
          id: '1',
          title: 'Un titre',
          body: List.generate(8, (i) => 'Ligne $i du détail').join('\n'),
        ),
      ),
    );

    expect(find.text('Un titre'), findsOneWidget);
    expect(find.textContaining('Ligne 7 du détail'), findsOneWidget);
    expect(find.text('Voir plus'), findsNothing);
    expect(find.byType(FeedPostActions), findsOneWidget);
  });

  testWidgets('lists comments and posts a new one on the detail page', (
    tester,
  ) async {
    final repo = FakeFeedRepository()
      ..commentsByPost['1'] = const [
        PostComment(
          id: 'c1',
          body: 'Amen',
          authorName: 'Léa',
          authorAvatarUrl: 'https://cdn.example/lea.jpg',
        ),
      ];
    await tester.pumpWidget(_detail(fakePost(id: '1'), repo: repo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Amen'), findsOneWidget);
    expect(find.text('Léa'), findsOneWidget);
    expect(find.text('Aucun commentaire pour le moment'), findsNothing);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.minLines, 1);
    expect(field.maxLines, 4);

    await tester.enterText(find.byType(TextField), 'Merci Seigneur');
    await tester.pump();
    await tester.tap(find.byTooltip('Envoyer le commentaire'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Merci Seigneur'), findsOneWidget);
    expect(repo.addedBodies, ['Merci Seigneur']);
    expect(find.text('2'), findsWidgets);
  });

  testWidgets('shows a comments skeleton while loading', (tester) async {
    final repo = _SlowCommentsRepository()
      ..commentsByPost['1'] = const [
        PostComment(id: 'c1', body: 'Amen', authorName: 'Léa'),
      ];
    await tester.pumpWidget(_detail(fakePost(id: '1'), repo: repo));
    await tester.pump();
    expect(find.byType(FeedCommentsSkeleton), findsOneWidget);
    repo.complete();
    await tester.pumpAndSettle();
    expect(find.byType(FeedCommentsSkeleton), findsNothing);
    expect(find.text('Amen'), findsOneWidget);
  });

  testWidgets('collapses extra replies behind Voir les réponses', (
    tester,
  ) async {
    final repo = FakeFeedRepository()
      ..commentsByPost['1'] = const [
        PostComment(id: 'c1', body: 'Amen', authorName: 'Léa'),
        PostComment(id: 'c2', body: 'Oui', authorName: 'Paul', parentId: 'c1'),
        PostComment(
          id: 'c3',
          body: 'Amen aussi',
          authorName: 'Eva',
          parentId: 'c1',
        ),
        PostComment(
          id: 'c4',
          body: 'Merci',
          authorName: 'Jean',
          parentId: 'c1',
        ),
      ];
    await tester.pumpWidget(_detail(fakePost(id: '1'), repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('Oui'), findsOneWidget);
    expect(find.text('Amen aussi'), findsOneWidget);
    expect(find.text('Merci'), findsNothing);
    expect(find.text('Voir 1 réponse'), findsOneWidget);

    await tester.ensureVisible(find.text('Voir 1 réponse'));
    await tester.pump();
    await tester.tap(find.text('Voir 1 réponse'));
    await tester.pump();
    expect(find.text('Merci'), findsOneWidget);
  });

  testWidgets('replying to a comment threads under the parent', (tester) async {
    final repo = FakeFeedRepository()
      ..commentsByPost['1'] = const [
        PostComment(id: 'c1', body: 'Amen', authorName: 'Léa'),
      ];
    await tester.pumpWidget(_detail(fakePost(id: '1'), repo: repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Répondre'));
    await tester.pump();

    expect(find.text('Réponse à Léa'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'Oui');
    await tester.pump();
    await tester.tap(find.byTooltip('Envoyer le commentaire'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Oui'), findsOneWidget);
    expect(repo.commentsByPost['1']!.last.parentId, 'c1');
  });

  testWidgets('shows empty comments copy', (tester) async {
    await tester.pumpWidget(_detail(fakePost(id: 'empty')));
    await tester.pumpAndSettle();
    expect(find.text('Aucun commentaire pour le moment'), findsOneWidget);
  });

  testWidgets('gallery detail pages through media urls', (tester) async {
    await tester.pumpWidget(
      _detail(
        fakePost(
          id: 'g',
          mediaType: PostMediaType.gallery,
          imageUrl: 'https://cdn.example/1.jpg',
          mediaUrls: const [
            'https://cdn.example/1.jpg',
            'https://cdn.example/2.jpg',
          ],
        ),
      ),
    );

    expect(find.byType(FeedGalleryView), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
  });

  testWidgets('share action opens the share sheet with post title', (
    tester,
  ) async {
    final sheet = _FakeShareSheet();
    final repo = FakeFeedRepository();
    await tester.pumpWidget(
      _detail(
        fakePost(id: '1', title: 'Enseignement'),
        repo: repo,
        sheet: sheet,
      ),
    );
    await tester.tap(find.byIcon(CupertinoIcons.square_arrow_up));
    await tester.pump();
    expect(sheet.texts, ['Enseignement']);
    expect(repo.shared, ['1']);
  });
}

class _SlowCommentsRepository extends FakeFeedRepository {
  final _gate = Completer<void>();

  void complete() => _gate.complete();

  @override
  Future<Result<List<PostComment>>> fetchComments(String postId) async {
    await _gate.future;
    return super.fetchComments(postId);
  }
}
