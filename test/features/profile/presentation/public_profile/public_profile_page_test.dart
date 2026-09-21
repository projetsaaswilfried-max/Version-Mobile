import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/discover/presentation/widgets/discover_profile_content.dart';
import 'package:agapeo/features/feed/di/feed_providers.dart';
import 'package:agapeo/features/profile/di/profile_providers.dart';
import 'package:agapeo/features/profile/presentation/public_profile/public_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/feed_test_fakes.dart';
import '../../../../helpers/profile_account_test_fakes.dart';

void main() {
  testWidgets('shows Discover-style profile sections', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileAccountRepositoryProvider.overrideWithValue(
            FakeProfileAccountRepository(),
          ),
          feedRepositoryProvider.overrideWithValue(FakeFeedRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const PublicProfilePage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(DiscoverProfileContent), findsOneWidget);
    expect(find.text('Léa Martin'), findsOneWidget);
    expect(find.text(' (28)'), findsOneWidget);
    expect(find.text('Paris'), findsOneWidget);
    expect(find.text('À propos'), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Foi'), findsOneWidget);
    expect(find.text('Évangélique'), findsOneWidget);
    expect(find.text('Pourquoi le mariage'), findsOneWidget);
    expect(find.text('Verset préféré'), findsOneWidget);
    expect(find.text('Valeurs'), findsOneWidget);
    expect(find.text('Loisirs'), findsOneWidget);
    expect(find.text('Qualités'), findsOneWidget);
  });

  testWidgets('shows Publications when author has personal posts', (
    tester,
  ) async {
    final feed = FakeFeedRepository()
      ..myPosts = [fakePost(id: 'perso-1', body: 'Mon verset du jour')];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileAccountRepositoryProvider.overrideWithValue(
            FakeProfileAccountRepository(),
          ),
          feedRepositoryProvider.overrideWithValue(feed),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const PublicProfilePage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Publications'), findsOneWidget);
    expect(find.text('Mon verset du jour'), findsOneWidget);
  });
}
