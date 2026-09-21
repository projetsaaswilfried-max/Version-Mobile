import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/core/theme/app_spacing.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:agapeo/features/auth/presentation/welcome/welcome_page.dart';
import 'package:agapeo/features/discover/di/discover_providers.dart';
import 'package:agapeo/features/discover/domain/entities/visitor_context.dart';
import 'package:agapeo/features/discover/domain/scoring/compatibility_traits.dart';
import 'package:agapeo/features/discover/presentation/discover_body.dart';
import 'package:agapeo/features/feed/di/feed_providers.dart';
import 'package:agapeo/features/feed/presentation/feed_body.dart';
import 'package:agapeo/features/home/presentation/home_shell_controller.dart';
import 'package:agapeo/features/home/presentation/home_shell_page.dart';
import 'package:agapeo/features/home/presentation/tabs/messages_tab_page.dart';
import 'package:agapeo/features/notifications/di/notifications_providers.dart';
import 'package:agapeo/features/notifications/presentation/notifications_page.dart';
import 'package:agapeo/features/home/presentation/widgets/home_floating_nav_bar.dart';
import 'package:agapeo/features/messages/di/messages_providers.dart';
import 'package:agapeo/features/messages/presentation/messages_body.dart';
import 'package:agapeo/features/profile/di/profile_providers.dart';
import 'package:agapeo/features/profile/domain/entities/profile_completeness.dart';
import 'package:agapeo/features/profile/presentation/my_profile/my_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/auth_test_fakes.dart';
import '../../../helpers/discover_test_fakes.dart';
import '../../../helpers/feed_test_fakes.dart';
import '../../../helpers/messages_test_fakes.dart';
import '../../../helpers/notifications_test_fakes.dart';
import '../../../helpers/profile_test_fakes.dart';

void main() {
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  Future<void> pumpShell(
    WidgetTester tester, {
    FakeAuthRepository? auth,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            auth ??
                FakeAuthRepository(
                  currentSession: const AuthSession(
                    id: '1',
                    email: 'user@test.co',
                  ),
                ),
          ),
          feedRepositoryProvider.overrideWithValue(FakeFeedRepository()),
          discoverRepositoryProvider.overrideWithValue(
            FakeDiscoverRepository(
              candidates: Ok([fakeDiscoverProfile('d1', displayName: 'Alice')]),
            ),
          ),
          messagesRepositoryProvider.overrideWithValue(
            FakeMessagesRepository(),
          ),
          notificationsRepositoryProvider.overrideWithValue(
            FakeNotificationsRepository(),
          ),
          profileCompletenessProvider.overrideWith(
            (ref) async =>
                const ProfileCompleteness(isComplete: true, missingKeys: []),
          ),
          profileFieldsRepositoryProvider.overrideWithValue(
            FakeProfileFieldsRepository(
              result: Ok(fakeProfileFieldsSnapshot()),
            ),
          ),
          myProfileRepositoryProvider.overrideWithValue(
            FakeMyProfileRepository(fetchResult: Ok(fakeMyProfile())),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const HomeShellPage()),
      ),
    );
  }

  testWidgets('shows four nav destinations and no fifth', (tester) async {
    await pumpShell(tester);

    expect(find.byTooltip('Fil'), findsOneWidget);
    expect(find.byTooltip('Découvrir'), findsOneWidget);
    expect(find.byTooltip('Messages'), findsOneWidget);
    expect(find.byTooltip('Profil'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(HomeFloatingNavBar),
        matching: find.text('Fil'),
      ),
      findsNothing,
    );
    expect(find.byType(HomeFloatingNavBar), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationDestination), findsNothing);
  });

  testWidgets('does not mount the feed until Fil is visited, then keeps it', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              currentSession: const AuthSession(id: '1', email: 'user@test.co'),
            ),
          ),
          feedRepositoryProvider.overrideWithValue(FakeFeedRepository()),
          discoverRepositoryProvider.overrideWithValue(
            FakeDiscoverRepository(
              visitor: const Ok(
                VisitorContext(
                  id: 'visitor-1',
                  gender: 'MALE',
                  isVerified: true,
                  subscriptionStatus: 'ACTIVE',
                  traits: CompatibilityTraits(),
                ),
              ),
              candidates: Ok([fakeDiscoverProfile('d1', displayName: 'Alice')]),
            ),
          ),
          messagesRepositoryProvider.overrideWithValue(
            FakeMessagesRepository(),
          ),
          notificationsRepositoryProvider.overrideWithValue(
            FakeNotificationsRepository(),
          ),
          profileCompletenessProvider.overrideWith(
            (ref) async =>
                const ProfileCompleteness(isComplete: true, missingKeys: []),
          ),
          homeShellIndexProvider.overrideWith(_DiscoverFirst.new),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const HomeShellPage()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(FeedBody, skipOffstage: false), findsNothing);
    expect(find.byType(DiscoverBody), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bientôt'), findsNothing);

    await tester.tap(find.byTooltip('Fil'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(FeedBody), findsOneWidget);

    await tester.tap(find.byTooltip('Découvrir'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(FeedBody, skipOffstage: false), findsOneWidget);
    expect(find.byType(FeedBody), findsNothing);
  });

  testWidgets('Messages tab shows empty inbox instead of Bientôt', (
    tester,
  ) async {
    await pumpShell(tester);
    await tester.tap(find.byTooltip('Messages'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(MessagesTabPage), findsOneWidget);
    expect(find.byType(MessagesBody), findsOneWidget);
    expect(find.text('Aucune conversation'), findsOneWidget);
    expect(find.text('Bientôt'), findsNothing);
  });

  testWidgets('bell opens notifications without badge at zero', (tester) async {
    await pumpShell(tester);

    expect(find.byTooltip('Notifications'), findsOneWidget);
    expect(find.byType(Badge), findsNothing);

    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsPage), findsOneWidget);
    expect(find.text('Notifications'), findsWidgets);
  });

  testWidgets('profile Modifier opens Mon Profil', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.byTooltip('Profil'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Modifier mon profil'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(MyProfilePage), findsOneWidget);
  });

  testWidgets('profile Déconnexion opens WelcomePage', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.byTooltip('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Léa Martin'), findsOneWidget);
    final logout = find.text('Déconnexion');
    await tester.scrollUntilVisible(
      logout,
      AppSpacing.xxxl,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(logout);
    await tester.pumpAndSettle();

    expect(find.text('Se déconnecter ?'), findsOneWidget);
    await tester.tap(find.text('Déconnexion').last);
    await tester.pumpAndSettle();

    expect(find.byType(WelcomePage), findsOneWidget);
  });

  test('homeShellIndexProvider est autoDispose', () {
    expect(homeShellIndexProvider.isAutoDispose, isTrue);
  });

  test(
    'l\'index sélectionné revient à Fil (0) après démontage du shell',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final subscription = container.listen(homeShellIndexProvider, (_, _) {});
      container.read(homeShellIndexProvider.notifier).select(2);
      expect(container.read(homeShellIndexProvider), 2);

      subscription.close();
      await Future<void>.delayed(Duration.zero);

      expect(container.read(homeShellIndexProvider), 0);
    },
  );
}

class _DiscoverFirst extends HomeShellController {
  @override
  int build() => 1;
}
