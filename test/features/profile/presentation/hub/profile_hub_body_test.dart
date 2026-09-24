import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/core/theme/app_spacing.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:agapeo/features/feed/di/feed_providers.dart';
import 'package:agapeo/features/feed/presentation/pages/my_posts_page.dart';
import 'package:agapeo/features/home/presentation/tabs/profile_tab_page.dart';
import 'package:agapeo/features/onboarding/presentation/profile_onboarding/onboarding_flow_page.dart';
import 'package:agapeo/features/premium/presentation/premium_plan_page.dart';
import 'package:agapeo/features/profile/di/profile_providers.dart';
import 'package:agapeo/features/profile/domain/entities/profile_hub_section.dart';
import 'package:agapeo/features/profile/presentation/faith/faith_page.dart';
import 'package:agapeo/features/profile/presentation/favorites/favorites_page.dart';
import 'package:agapeo/features/profile/presentation/interested/interested_page.dart';
import 'package:agapeo/features/profile/presentation/more_info/more_info_page.dart';
import 'package:agapeo/features/profile/presentation/my_profile/my_profile_page.dart';
import 'package:agapeo/features/profile/presentation/privacy/privacy_page.dart';
import 'package:agapeo/features/profile/presentation/public_profile/public_profile_page.dart';
import 'package:agapeo/features/profile/presentation/security/account_security_page.dart';
import 'package:agapeo/features/profile/presentation/security/add_profile_photo_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/auth_test_fakes.dart';
import '../../../../helpers/feed_test_fakes.dart';
import '../../../../helpers/profile_account_test_fakes.dart';
import '../../../../helpers/profile_test_fakes.dart';

void main() {
  Future<void> pumpTab(
    WidgetTester tester, {
    FakeProfileFieldsRepository? fields,
    Size? surfaceSize,
  }) async {
    tester.view.physicalSize = surfaceSize ?? const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    if (surfaceSize != null) {
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              currentSession: const AuthSession(
                id: '1',
                email: 'lea@agapeo.love',
              ),
            ),
          ),
          profileFieldsRepositoryProvider.overrideWithValue(
            fields ??
                FakeProfileFieldsRepository(
                  result: Ok(fakeProfileFieldsSnapshot()),
                ),
          ),
          myProfileRepositoryProvider.overrideWithValue(
            FakeMyProfileRepository(fetchResult: Ok(fakeMyProfile())),
          ),
          profileAccountRepositoryProvider.overrideWithValue(
            FakeProfileAccountRepository(),
          ),
          feedRepositoryProvider.overrideWithValue(FakeFeedRepository()),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const ProfileTabPage()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> tapSection(WidgetTester tester, String label) async {
    final finder = find.text(label);
    await tester.scrollUntilVisible(
      finder,
      AppSpacing.xxxl,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('shows identity, verified badge and 9 sections', (tester) async {
    await pumpTab(tester);

    expect(find.text('Léa Martin'), findsOneWidget);
    expect(find.bySemanticsLabel('Vérifié'), findsOneWidget);
    expect(find.text('Voir mon profil public'), findsOneWidget);
    expect(find.byTooltip('Modifier mon profil'), findsOneWidget);
    expect(find.text('Déconnexion'), findsOneWidget);
    for (final section in ProfileHubSection.values) {
      final finder = find.text(section.label);
      await tester.scrollUntilVisible(
        finder,
        AppSpacing.xxxl,
        scrollable: find.byType(Scrollable).first,
      );
      expect(finder, findsOneWidget);
    }
  });

  testWidgets(
    'pull-to-refresh reflects a new verification status (profileFieldsProvider)',
    (tester) async {
      final fields = FakeProfileFieldsRepository(
        result: Ok(
          fakeProfileFieldsSnapshot(
            hasPrimaryPhoto: true,
            photoVerificationStatus: 'PENDING',
          ),
        ),
      );
      await pumpTab(tester, fields: fields);

      expect(find.text('Vérification en cours'), findsOneWidget);

      fields.result = Ok(
        fakeProfileFieldsSnapshot(
          hasPrimaryPhoto: true,
          photoVerificationStatus: 'VERIFIED',
        ),
      );
      final refreshIndicator = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );
      await refreshIndicator.onRefresh();
      await tester.pumpAndSettle();

      expect(find.text('Vérification en cours'), findsNothing);
    },
  );

  testWidgets('opens Mes Publications', (tester) async {
    await pumpTab(tester);
    await tapSection(tester, 'Mes Publications');
    expect(find.byType(MyPostsPage), findsOneWidget);
  });

  testWidgets('opens public profile preview', (tester) async {
    await pumpTab(tester);

    await tester.tap(find.text('Voir mon profil public'));
    await tester.pumpAndSettle();
    expect(find.byType(PublicProfilePage), findsOneWidget);
  });

  testWidgets('opens remaining hub sections', (tester) async {
    await pumpTab(tester);

    Future<void> open(String label, Type page) async {
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tapSection(tester, label);
      expect(find.byType(page), findsOneWidget);
    }

    await tapSection(tester, 'Ma Foi');
    expect(find.byType(FaithPage), findsOneWidget);

    await open('Plus d\'infos', MoreInfoPage);
    await open('Mon Plan', PremiumPlanPage);
    await open('Mes Favoris', FavoritesPage);
    await open('Qui s\'intéresse à moi', InterestedPage);
    await open('Confidentialité', PrivacyPage);
    await open('Compte & Sécurité', AccountSecurityPage);
  });

  testWidgets('opens Mon Profil editor', (tester) async {
    await pumpTab(tester);
    await tapSection(tester, 'Mon Profil');
    expect(find.byType(MyProfilePage), findsOneWidget);
  });

  testWidgets('Modifier opens Mon Profil', (tester) async {
    await pumpTab(tester);

    await tester.tap(find.byTooltip('Modifier mon profil'));
    await tester.pumpAndSettle();
    expect(find.byType(MyProfilePage), findsOneWidget);
    expect(find.byType(OnboardingFlowPage), findsNothing);
  });

  testWidgets(
    'banner opens Mon Profil when essentials present',
    (tester) async {
      await pumpTab(
        tester,
        fields: FakeProfileFieldsRepository(
          result: Ok(
            fakeProfileFieldsSnapshot(
              hasPrimaryPhoto: true,
              hasFaithConfession: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Complète ton profil'), findsOneWidget);
      await tester.tap(find.text('Complète ton profil'));
      await tester.pumpAndSettle();
      expect(find.byType(MyProfilePage), findsOneWidget);
      expect(find.byType(OnboardingFlowPage), findsNothing);
    },
  );

  testWidgets(
    'banner opens the dedicated photo page when photo is missing',
    (tester) async {
      await pumpTab(
        tester,
        fields: FakeProfileFieldsRepository(
          result: Ok(
            fakeProfileFieldsSnapshot(
              hasPrimaryPhoto: false,
              hasFaithConfession: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Complète ton profil'), findsOneWidget);
      await tester.tap(find.text('Complète ton profil'));
      await tester.pumpAndSettle();
      expect(find.byType(AddProfilePhotoPage), findsOneWidget);
      expect(find.byType(MyProfilePage), findsNothing);
    },
  );

  testWidgets(
    'banner opens onboarding when essentials missing',
    (tester) async {
      await pumpTab(
        tester,
        fields: FakeProfileFieldsRepository(
          result: Ok(
            fakeProfileFieldsSnapshot(
              hasGender: false,
              hasBirthDate: false,
              hasCountry: false,
              hasPrimaryPhoto: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Complète ton profil'), findsOneWidget);
      await tester.tap(find.text('Complète ton profil'));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingFlowPage), findsOneWidget);
      expect(find.byType(MyProfilePage), findsNothing);
    },
  );

  testWidgets('error keeps logout and retries', (tester) async {
    final repo = FakeProfileFieldsRepository(
      result: const Err(NetworkFailure('offline')),
    );
    await pumpTab(tester, fields: repo);

    expect(find.text('Impossible de charger le profil'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.text('Déconnexion'), findsOneWidget);

    repo.result = Ok(fakeProfileFieldsSnapshot());
    await tester.tap(find.text('Réessayer'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Léa Martin'), findsOneWidget);
    expect(find.text('Déconnexion'), findsOneWidget);
  });

  testWidgets('last section and logout stay tappable on a phone viewport', (
    tester,
  ) async {
    await pumpTab(tester, surfaceSize: const Size(390, 844));

    final section = find.text('Compte & Sécurité');
    await tester.scrollUntilVisible(
      section,
      AppSpacing.xxxl,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(section);
    await tester.pumpAndSettle();
    expect(find.byType(AccountSecurityPage), findsOneWidget);
  });
}
