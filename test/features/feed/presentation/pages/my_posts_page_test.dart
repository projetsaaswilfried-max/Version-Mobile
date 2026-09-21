import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/feed/di/feed_providers.dart';
import 'package:agapeo/features/feed/domain/entities/post_media_type.dart';
import 'package:agapeo/features/feed/presentation/pages/my_posts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/feed_test_fakes.dart';

void main() {
  testWidgets('empty state offers create CTA', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedRepositoryProvider.overrideWithValue(FakeFeedRepository()),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const MyPostsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mes publications'), findsWidgets);
    expect(find.text('Aucune publication pour le moment'), findsOneWidget);
    expect(find.text('Créer une publication'), findsOneWidget);
  });

  testWidgets('lists personal posts', (tester) async {
    final repo = FakeFeedRepository()
      ..myPosts = [fakePost(id: 'mine', body: 'Souvenir du dimanche')];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [feedRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(theme: AppTheme.light, home: const MyPostsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Souvenir du dimanche'), findsOneWidget);
    expect(find.text('Aucune publication pour le moment'), findsNothing);
  });

  testWidgets('shows engagement stats and a media preview when present', (
    tester,
  ) async {
    final repo = FakeFeedRepository()
      ..myPosts = [
        fakePost(
          id: 'mine',
          body: 'Un culte béni ce dimanche',
          mediaType: PostMediaType.image,
          imageUrl: 'https://cdn.example/culte.jpg',
        ),
      ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [feedRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(theme: AppTheme.light, home: const MyPostsPage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.byIcon(Icons.mode_comment_outlined), findsOneWidget);
  });
}
