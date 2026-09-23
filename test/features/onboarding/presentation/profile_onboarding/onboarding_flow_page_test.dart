import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_birth_date_field.dart';
import 'package:agapeo/core/widgets/app_country_picker.dart';
import 'package:agapeo/core/widgets/app_gender_cards.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:agapeo/features/feed/di/feed_providers.dart';
import 'package:agapeo/features/home/presentation/home_shell_page.dart';
import 'package:agapeo/features/onboarding/di/onboarding_providers.dart';
import 'package:agapeo/features/onboarding/domain/entities/onboarding_submit_payload.dart';
import 'package:agapeo/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:agapeo/features/onboarding/presentation/profile_onboarding/onboarding_draft.dart';
import 'package:agapeo/features/onboarding/presentation/profile_onboarding/onboarding_flow_controller.dart';
import 'package:agapeo/features/onboarding/presentation/profile_onboarding/onboarding_flow_page.dart';
import 'package:agapeo/features/notifications/di/notifications_providers.dart';
import 'package:agapeo/features/profile/di/profile_providers.dart';
import 'package:agapeo/features/profile/presentation/hub/widgets/profile_completion_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/auth_test_fakes.dart';
import '../../../../helpers/feed_test_fakes.dart';
import '../../../../helpers/notifications_test_fakes.dart';
import '../../../../helpers/profile_account_test_fakes.dart';
import '../../../../helpers/profile_test_fakes.dart';

class _OkOnboardingRepo implements OnboardingRepository {
  @override
  Future<Result<void>> submit(OnboardingSubmitPayload payload) async =>
      const Ok(null);

  @override
  Future<Result<void>> finishWithoutVerification(
    OnboardingSubmitPayload payload,
  ) async => const Ok(null);
}

const _skipPhotoWarning =
    'Sans photo, ton profil ne sera pas vérifié ni visible. '
    'Tu pourras en ajouter plus tard.';

void _goToPhotoStep(ProviderContainer container) {
  final controller = container.read(onboardingFlowProvider.notifier);
  controller.updateDraft(
    (d) => d.copyWith(
      gender: OnboardingGender.woman,
      birthDate: DateTime(1990, 1, 1),
      country: 'France',
      faithConfession: 'Catholique',
      maritalStatus: OnboardingMaritalStatus.single,
      whyMarriage: 'Le mariage',
      hobbies: ['Randonnée'],
    ),
  );
  expect(controller.next(), isTrue);
  expect(controller.next(), isTrue);
  expect(controller.next(), isTrue);
}

void _goToRecapStep(ProviderContainer container) {
  _goToPhotoStep(container);
  final controller = container.read(onboardingFlowProvider.notifier);
  expect(controller.next(), isTrue); // photo -> selfie
  controller.updateDraft(
    (d) => d.copyWith(selfiePath: '/tmp/onboarding-test-selfie.jpg'),
  );
  expect(controller.next(), isTrue); // selfie -> recap
}

void _goToFaithStep(ProviderContainer container) {
  final controller = container.read(onboardingFlowProvider.notifier);
  controller.updateDraft(
    (d) => d.copyWith(
      gender: OnboardingGender.woman,
      birthDate: DateTime(1990, 1, 1),
      country: 'France',
    ),
  );
  expect(controller.next(), isTrue);
}

void main() {
  testWidgets('shell profile opens onboarding flow', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          feedRepositoryProvider.overrideWithValue(FakeFeedRepository()),
          notificationsRepositoryProvider.overrideWithValue(
            FakeNotificationsRepository(),
          ),
          profileFieldsRepositoryProvider.overrideWithValue(
            FakeProfileFieldsRepository(
              result: Ok(fakeProfileFieldsSnapshot(hasGender: false)),
            ),
          ),
          myProfileRepositoryProvider.overrideWithValue(
            FakeMyProfileRepository(fetchResult: Ok(fakeMyProfile())),
          ),
          profileAccountRepositoryProvider.overrideWithValue(
            FakeProfileAccountRepository(),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const HomeShellPage()),
      ),
    );

    await tester.tap(find.byTooltip('Profil'));
    await tester.pumpAndSettle();
    // Le crayon "Modifier mon profil" ouvre désormais MyProfilePage ; c'est
    // la bannière de complétion (champ manquant : genre) qui ouvre
    // l'onboarding.
    await tester.tap(find.byType(ProfileCompletionBanner));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingFlowPage), findsOneWidget);
    expect(find.text('Parle-nous de toi'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
  });

  testWidgets('progress and custom widgets on O01', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingFlowPage(),
        ),
      ),
    );

    expect(find.byType(AppGenderCards), findsOneWidget);
    expect(find.byType(AppBirthDateField), findsOneWidget);
    expect(find.byType(AppCountryPicker), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('Continuer'), findsOneWidget);
  });

  testWidgets('no Revenir plus tard on step 0', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingFlowPage(),
        ),
      ),
    );

    expect(find.text('Revenir plus tard'), findsNothing);
    expect(find.text('Passer'), findsNothing);
  });

  testWidgets('Continuer stays disabled until essentials are filled', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingFlowPage(),
        ),
      ),
    );

    final continuer = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continuer'),
    );
    expect(continuer.onPressed, isNull);

    await tester.tap(find.text('Continuer'));
    await tester.pump();

    expect(find.text('Choisis ton genre.'), findsNothing);
    expect(find.text('Ta foi'), findsNothing);
  });

  testWidgets('Continuer enables once essentials are complete', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingFlowPage(),
        ),
      ),
    );

    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Continuer'),
          )
          .onPressed,
      isNull,
    );

    container
        .read(onboardingFlowProvider.notifier)
        .updateDraft(
          (d) => d.copyWith(
            gender: OnboardingGender.woman,
            birthDate: DateTime(1990, 1, 1),
            country: 'France',
          ),
        );
    await tester.pump();

    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Continuer'),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('Passer on photo step shows skip-photo dialog', (tester) async {
    final container = ProviderContainer(
      overrides: [
        onboardingRepositoryProvider.overrideWithValue(_OkOnboardingRepo()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingFlowPage(),
        ),
      ),
    );

    _goToPhotoStep(container);
    await tester.pumpAndSettle();

    expect(find.text('Passer'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
    expect(find.text('Revenir plus tard'), findsNothing);
    expect(find.text('Terminer'), findsNothing);

    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();

    expect(find.text(_skipPhotoWarning), findsOneWidget);
    expect(find.text('Continuer sans photo ?'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
    expect(find.text('Continuer sans photo'), findsOneWidget);
  });

  testWidgets('no Revenir plus tard on step 1 after valid essentials', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingFlowPage(),
        ),
      ),
    );

    _goToFaithStep(container);
    await tester.pumpAndSettle();

    expect(find.text('Ta foi'), findsOneWidget);
    expect(find.text('Revenir plus tard'), findsNothing);
    expect(find.text('Passer'), findsNothing);
  });

  testWidgets('Terminer with photo completes and opens HomeShell', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        onboardingRepositoryProvider.overrideWithValue(_OkOnboardingRepo()),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(
            currentSession: const AuthSession(id: '1', email: 'u@t.co'),
          ),
        ),
        feedRepositoryProvider.overrideWithValue(FakeFeedRepository()),
        notificationsRepositoryProvider.overrideWithValue(
          FakeNotificationsRepository(),
        ),
        profileAccountRepositoryProvider.overrideWithValue(
          FakeProfileAccountRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(onboardingFlowProvider, (_, _) {}, fireImmediately: true);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingFlowPage(),
        ),
      ),
    );

    _goToRecapStep(container);
    container
        .read(onboardingFlowProvider.notifier)
        .updateDraft(
          (d) => d.copyWith(profilePhotoPath: '/tmp/onboarding-test-photo.jpg'),
        );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Terminer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // _onCompleted (postFrameCallback) programme lui-même AppToast.show
    // (autre postFrameCallback) : il faut un frame de plus pour l'overlay.
    await tester.pump();

    expect(container.read(onboardingFlowProvider).completedLocally, isTrue);
    expect(container.read(onboardingFlowProvider).skippedPhoto, isFalse);
    expect(find.textContaining('Profil enregistré'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(HomeShellPage), findsOneWidget);
    expect(find.byType(OnboardingFlowPage), findsNothing);
  });

  testWidgets('confirm skip photo completes and opens HomeShell', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        onboardingRepositoryProvider.overrideWithValue(_OkOnboardingRepo()),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(
            currentSession: const AuthSession(id: '1', email: 'u@t.co'),
          ),
        ),
        feedRepositoryProvider.overrideWithValue(FakeFeedRepository()),
        notificationsRepositoryProvider.overrideWithValue(
          FakeNotificationsRepository(),
        ),
        profileAccountRepositoryProvider.overrideWithValue(
          FakeProfileAccountRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(onboardingFlowProvider, (_, _) {}, fireImmediately: true);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingFlowPage(),
        ),
      ),
    );

    _goToPhotoStep(container);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuer sans photo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // _onCompleted (postFrameCallback) programme lui-même AppToast.show
    // (autre postFrameCallback) : il faut un frame de plus pour l'overlay.
    await tester.pump();

    expect(container.read(onboardingFlowProvider).completedLocally, isTrue);
    expect(container.read(onboardingFlowProvider).skippedPhoto, isTrue);
    expect(find.text('Profil enregistré sans photo.'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(HomeShellPage), findsOneWidget);
    expect(find.byType(OnboardingFlowPage), findsNothing);
  });

  testWidgets('recap has Terminer only — no Passer or Revenir plus tard', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingFlowPage(),
        ),
      ),
    );

    _goToRecapStep(container);
    await tester.pumpAndSettle();

    expect(find.text('Terminer'), findsOneWidget);
    expect(find.text('Passer'), findsNothing);
    expect(find.text('Revenir plus tard'), findsNothing);
  });

  testWidgets('recap lists answers and can jump back', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingFlowPage(),
        ),
      ),
    );

    _goToRecapStep(container);
    await tester.pumpAndSettle();

    expect(find.text('Récapitulatif'), findsOneWidget);
    expect(find.text('Vérifie tes infos'), findsOneWidget);
    expect(find.text('Femme'), findsOneWidget);
    expect(find.text('France'), findsOneWidget);
    expect(find.text('Catholique'), findsOneWidget);

    await tester.tap(find.text('Genre'));
    await tester.pumpAndSettle();
    expect(find.text('Parle-nous de toi'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
  });
}
