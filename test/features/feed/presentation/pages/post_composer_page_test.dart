import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/feed/di/feed_providers.dart';
import 'package:agapeo/features/feed/presentation/pages/post_composer_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/feed_test_fakes.dart';

void main() {
  testWidgets('refuses 601 characters', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedRepositoryProvider.overrideWithValue(FakeFeedRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const PostComposerPage(),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'a' * 601);
    await tester.pump();
    await tester.tap(find.text('Publier'));
    await tester.pumpAndSettle();

    // Publier is disabled over the limit; text stays, no pop.
    expect(find.text('Nouvelle publication'), findsOneWidget);
    expect(find.text('601 / 600'), findsOneWidget);
  });

  testWidgets('shows personal-profile hint and publish action', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedRepositoryProvider.overrideWithValue(FakeFeedRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const PostComposerPage(),
        ),
      ),
    );

    expect(
      find.textContaining('Visible sur ton profil public'),
      findsOneWidget,
    );
    expect(find.text('Publier'), findsOneWidget);
    expect(find.byTooltip('Ajouter un média'), findsOneWidget);
  });
}
