import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/core/theme/app_colors.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/feed/di/feed_providers.dart';
import 'package:agapeo/features/feed/domain/entities/feed_page.dart';
import 'package:agapeo/features/feed/domain/entities/post_comment.dart';
import 'package:agapeo/features/feed/presentation/widgets/feed_comments_sheet.dart';
import 'package:agapeo/features/feed/presentation/widgets/feed_comments_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/feed_test_fakes.dart';

Widget _sheet(FakeFeedRepository repo) {
  repo.result = Ok(FeedPage(items: [fakePost(id: '1')], hasMore: false));
  return ProviderScope(
    overrides: [feedRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: FeedCommentsSheet(post: fakePost(id: '1')),
      ),
    ),
  );
}

void main() {
  testWidgets('sheet lists comments, shows composer and sends', (tester) async {
    final repo = FakeFeedRepository()
      ..commentsByPost['1'] = const [
        PostComment(id: 'c1', body: 'Amen', authorName: 'Léa'),
      ];
    await tester.pumpWidget(_sheet(repo));
    await tester.pumpAndSettle();

    expect(find.text('Commentaires'), findsOneWidget);
    expect(find.text('Amen'), findsOneWidget);
    expect(find.byTooltip('Envoyer le commentaire'), findsOneWidget);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.minLines, 1);

    await tester.enterText(find.byType(TextField), 'Merci');
    await tester.pump();
    await tester.tap(find.byTooltip('Envoyer le commentaire'));
    await tester.pumpAndSettle();
    expect(find.text('Merci'), findsOneWidget);
    expect(repo.addedBodies, ['Merci']);
  });

  testWidgets('sheet replies to a comment', (tester) async {
    final repo = FakeFeedRepository()
      ..commentsByPost['1'] = const [
        PostComment(id: 'c1', body: 'Amen', authorName: 'Léa'),
      ];
    await tester.pumpWidget(_sheet(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Répondre'));
    await tester.pump();
    expect(find.text('Réponse à Léa'), findsWidgets);
    await tester.enterText(find.byType(TextField), 'Oui');
    await tester.pump();
    await tester.tap(find.byTooltip('Envoyer le commentaire'));
    await tester.pumpAndSettle();
    expect(repo.commentsByPost['1']!.last.parentId, 'c1');
  });

  testWidgets('sheet hides replies until Voir N réponses', (tester) async {
    final repo = FakeFeedRepository()
      ..commentsByPost['1'] = const [
        PostComment(id: 'c1', body: 'Amen', authorName: 'Léa'),
        PostComment(id: 'c2', body: 'Oui', authorName: 'Paul', parentId: 'c1'),
      ];
    await tester.pumpWidget(_sheet(repo));
    await tester.pumpAndSettle();
    expect(find.text('Oui'), findsNothing);
    expect(find.text('Voir 1 réponse'), findsOneWidget);
    await tester.tap(find.text('Voir 1 réponse'));
    await tester.pump();
    expect(find.text('Oui'), findsOneWidget);
    // Un seul toggle une fois déplié, positionné après la réponse (pas de
    // doublon sous le commentaire principal).
    expect(find.text('Masquer les réponses'), findsOneWidget);
    final replyY = tester.getCenter(find.text('Oui')).dy;
    final toggleY = tester.getCenter(find.text('Masquer les réponses')).dy;
    expect(toggleY, greaterThan(replyY));
  });

  testWidgets('sheet shows a rose verified badge for verified authors', (
    tester,
  ) async {
    final repo = FakeFeedRepository()
      ..commentsByPost['1'] = const [
        PostComment(
          id: 'c1',
          body: 'Amen',
          authorName: 'Léa',
          isVerified: true,
        ),
        PostComment(id: 'c2', body: 'Oui', authorName: 'Paul'),
      ];
    await tester.pumpWidget(_sheet(repo));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.verified), findsOneWidget);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.verified)).color,
      AppColors.light.primary,
    );
  });

  testWidgets('sheet shows a skeleton while loading', (tester) async {
    final repo = _SlowCommentsRepository();
    await tester.pumpWidget(_sheet(repo));
    await tester.pump();
    expect(find.byType(FeedCommentsSkeleton), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(FeedCommentsSkeleton), findsNothing);
  });
}

class _SlowCommentsRepository extends FakeFeedRepository {
  @override
  Future<Result<List<PostComment>>> fetchComments(String postId) async {
    await Future<void>.delayed(const Duration(milliseconds: 40));
    return super.fetchComments(postId);
  }
}
