import 'dart:async';

import 'package:agapeo/core/config/app_assets.dart';
import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/core/theme/app_colors.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/feed/di/feed_providers.dart';
import 'package:agapeo/features/feed/domain/entities/feed_filter.dart';
import 'package:agapeo/features/feed/domain/entities/feed_page.dart';
import 'package:agapeo/features/feed/domain/entities/post_category.dart';
import 'package:agapeo/features/feed/domain/entities/post_comment.dart';
import 'package:agapeo/features/feed/domain/entities/post_media_type.dart';
import 'package:agapeo/features/feed/presentation/feed_body.dart';
import 'package:agapeo/features/feed/presentation/pages/post_detail_page.dart';
import 'package:agapeo/features/feed/presentation/widgets/feed_post_actions.dart';
import 'package:agapeo/features/feed/presentation/widgets/feed_skeleton.dart';
import 'package:agapeo/features/home/presentation/tabs/feed_tab_page.dart';
import 'package:agapeo/features/notifications/di/notifications_providers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/feed_test_fakes.dart';
import '../../../helpers/notifications_test_fakes.dart';

void main() {
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });
  Future<void> pumpFeed(
    WidgetTester tester, {
    required FakeFeedRepository repo,
    bool tab = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedRepositoryProvider.overrideWithValue(repo),
          notificationsRepositoryProvider.overrideWithValue(
            FakeNotificationsRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: tab ? const FeedTabPage() : const Scaffold(body: FeedBody()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows all category chips on a single scrollable row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = FakeFeedRepository(
      result: const Ok(FeedPage(items: [], hasMore: false)),
    );
    await pumpFeed(tester, repo: repo);

    expect(find.text("Fil d'actualité"), findsOneWidget);
    expect(tester.getTopLeft(find.text("Fil d'actualité")).dx, closeTo(16, 1));
    expect(find.text('Officiel'), findsNothing);
    expect(find.text('Tout le fil'), findsOneWidget);
    expect(find.text('Enseignements'), findsOneWidget);
    expect(find.text('Témoignages'), findsOneWidget);
    expect(find.text('Atelier/Mariage'), findsOneWidget);
    expect(find.text('Conseils & Préparation'), findsOneWidget);
    expect(
      find.text('Pensées & Citations', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Annonce', skipOffstage: false), findsOneWidget);
    expect(find.text('Verset', skipOffstage: false), findsOneWidget);
    expect(find.text('Nouveauté', skipOffstage: false), findsOneWidget);
    expect(find.text('Plus'), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('tapping a category chip selects it directly', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = FakeFeedRepository(
      result: const Ok(FeedPage(items: [], hasMore: false)),
    );
    await pumpFeed(tester, repo: repo);

    final announcementChip = find.byKey(
      const ValueKey('feed-chip-announcement'),
    );
    await tester.ensureVisible(announcementChip);
    await tester.pumpAndSettle();
    await tester.tap(announcementChip);
    await tester.pumpAndSettle();

    expect(find.text('Annonce'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('shows empty state', (tester) async {
    final repo = FakeFeedRepository(
      result: const Ok(FeedPage(items: [], hasMore: false)),
    );
    await pumpFeed(tester, repo: repo);
    expect(find.text('Aucun post pour le moment'), findsOneWidget);
  });

  testWidgets('shows empty filtered copy after picking a category', (
    tester,
  ) async {
    final repo = FakeFeedRepository(
      result: const Ok(FeedPage(items: [], hasMore: false)),
    );
    await pumpFeed(tester, repo: repo);

    await tester.tap(find.text('Enseignements'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Aucun post dans cette catégorie'), findsOneWidget);
    expect(repo.calls.last.filter.category, PostCategory.teaching);
  });

  testWidgets('shows error and retries', (tester) async {
    final repo = FakeFeedRepository(result: const Err(NetworkFailure()));
    await pumpFeed(tester, repo: repo);

    expect(find.text('Impossible de charger le fil'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);

    repo.result = const Ok(FeedPage(items: [], hasMore: false));
    await tester.tap(find.text('Réessayer'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Aucun post pour le moment'), findsOneWidget);
  });

  testWidgets('renders text and quote cards with ignored actions', (
    tester,
  ) async {
    final repo = FakeFeedRepository(
      result: Ok(
        FeedPage(
          items: [
            fakePost(
              id: '1',
              title: 'Ne cours pas après le mariage',
              body: 'Texte officiel',
              category: PostCategory.advice,
              createdAt: DateTime.now().subtract(const Duration(hours: 2)),
              viewCount: 133,
            ),
            fakePost(
              id: '2',
              body: 'Aimez-vous les uns les autres',
              mediaType: PostMediaType.quoteCard,
              quoteAttribution: 'Jean 13.34',
              pinned: true,
            ),
          ],
          hasMore: false,
        ),
      ),
    );
    await pumpFeed(tester, repo: repo);

    expect(find.text('Texte officiel'), findsOneWidget);
    expect(find.text('Ne cours pas après le mariage'), findsOneWidget);
    expect(find.text('Aimez-vous les uns les autres'), findsOneWidget);
    expect(find.text('Jean 13.34'), findsOneWidget);
    expect(find.text('Équipe Agapeo'), findsWidgets);
    expect(find.byIcon(Icons.verified), findsWidgets);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.verified).first).color,
      AppColors.light.primary,
    );
    expect(find.text('Conseil'), findsOneWidget);
    expect(find.textContaining('il y a 2 h'), findsOneWidget);
    expect(find.text('133'), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsWidgets);
    expect(find.byIcon(Icons.visibility_outlined), findsWidgets);
    expect(find.byType(FeedPostActions), findsNWidgets(2));
    expect(find.byIcon(CupertinoIcons.heart), findsWidgets);
    expect(find.byKey(const ValueKey('feed-post-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('feed-post-2')), findsOneWidget);
  });

  testWidgets('tapping like updates the count', (tester) async {
    final repo = FakeFeedRepository(
      result: Ok(FeedPage(items: [fakePost(id: '1')], hasMore: false)),
    );
    await pumpFeed(tester, repo: repo);

    expect(find.text('2'), findsWidgets);
    await tester.tap(find.byIcon(CupertinoIcons.heart));
    await tester.pump();

    expect(find.byIcon(CupertinoIcons.heart_fill), findsOneWidget);
    expect(repo.liked['1'], isTrue);
  });

  testWidgets('comment action opens the comments sheet', (tester) async {
    final repo =
        FakeFeedRepository(
            result: Ok(
              FeedPage(
                items: [fakePost(id: '1', title: 'Titre long')],
                hasMore: false,
              ),
            ),
          )
          ..commentsByPost['1'] = const [
            PostComment(id: 'c1', body: 'Amen', authorName: 'Léa'),
          ];
    await pumpFeed(tester, repo: repo);

    await tester.tap(find.byIcon(CupertinoIcons.chat_bubble));
    await tester.pumpAndSettle();

    expect(find.text('Commentaires'), findsOneWidget);
    expect(find.text('Amen'), findsOneWidget);
    expect(find.byType(PostDetailPage), findsNothing);
  });

  testWidgets('tapping a card opens the post detail', (tester) async {
    final repo = FakeFeedRepository(
      result: Ok(
        FeedPage(
          items: [
            fakePost(
              id: '1',
              title: 'Titre long',
              body: 'Corps complet du post officiel',
            ),
          ],
          hasMore: false,
        ),
      ),
    );
    await pumpFeed(tester, repo: repo);

    await tester.tap(find.byKey(const ValueKey('feed-post-1')));
    await tester.pumpAndSettle();

    expect(find.byType(PostDetailPage), findsOneWidget);
    expect(find.text('Corps complet du post officiel'), findsWidgets);
    expect(find.text('Titre long'), findsWidgets);
  });

  testWidgets('shows skeleton while waiting', (tester) async {
    final repo = _SlowFeedRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedRepositoryProvider.overrideWithValue(repo),
          notificationsRepositoryProvider.overrideWithValue(
            FakeNotificationsRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: FeedBody()),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(FeedSkeleton), findsOneWidget);
    repo.complete();
    await tester.pump();
    await tester.pump();
  });

  testWidgets('FeedTabPage app bar shows Agapeo on the left', (
    tester,
  ) async {
    final repo = FakeFeedRepository(
      result: const Ok(FeedPage(items: [], hasMore: false)),
    );
    await pumpFeed(tester, repo: repo, tab: true);
    expect(find.text('Agapeo'), findsOneWidget);
    expect(find.text('Cercle Agape'), findsNothing);
    expect(find.text('Fil'), findsNothing);
    expect(find.text('Officiel'), findsNothing);
    expect(find.byTooltip('Notifications'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == AppAssets.logoFull,
      ),
      findsOneWidget,
    );
  });

  testWidgets('feed header chips and cards share one CustomScrollView', (
    tester,
  ) async {
    final repo = FakeFeedRepository(
      result: Ok(
        FeedPage(
          items: [fakePost(id: '1', body: 'Texte officiel')],
          hasMore: false,
        ),
      ),
    );
    await pumpFeed(tester, repo: repo);

    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
    expect(find.text("Fil d'actualité"), findsOneWidget);
    expect(find.text('Tout le fil'), findsOneWidget);
    expect(find.byKey(const ValueKey('feed-post-1')), findsOneWidget);
  });

  testWidgets('shows Voir plus when body exceeds four lines', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = FakeFeedRepository(
      result: Ok(
        FeedPage(
          items: [
            fakePost(
              id: 'long',
              body: List.generate(8, (i) => 'Ligne courte $i').join('\n'),
            ),
            fakePost(id: 'short', body: 'Court'),
          ],
          hasMore: false,
        ),
      ),
    );
    await pumpFeed(tester, repo: repo);

    expect(find.text('Voir plus'), findsOneWidget);
    await tester.tap(find.text('Voir plus'));
    await tester.pumpAndSettle();
    expect(find.byType(PostDetailPage), findsNothing);
    expect(find.text('Voir moins'), findsOneWidget);
  });
}

class _SlowFeedRepository extends FakeFeedRepository {
  _SlowFeedRepository() : super();

  final _gate = Completer<void>();

  void complete() => _gate.complete();

  @override
  Future<Result<FeedPage>> fetchPage({
    required FeedFilter filter,
    required int offset,
    required int limit,
  }) async {
    await _gate.future;
    return const Ok(FeedPage(items: [], hasMore: false));
  }
}
