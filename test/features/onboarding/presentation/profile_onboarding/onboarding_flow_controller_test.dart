import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/onboarding/di/onboarding_providers.dart';
import 'package:agapeo/features/onboarding/domain/entities/onboarding_draft.dart';
import 'package:agapeo/features/onboarding/domain/entities/onboarding_submit_payload.dart';
import 'package:agapeo/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:agapeo/features/onboarding/presentation/profile_onboarding/onboarding_flow_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _OkRepo implements OnboardingRepository {
  @override
  Future<Result<void>> submit(OnboardingSubmitPayload payload) async =>
      const Ok(null);

  @override
  Future<Result<void>> finishWithoutVerification(
    OnboardingSubmitPayload payload,
  ) async => const Ok(null);
}

void main() {
  group('OnboardingFlowController', () {
    late ProviderContainer container;
    final validDraft = OnboardingDraft(
      gender: OnboardingGender.woman,
      birthDate: DateTime(1995, 1, 1),
      country: 'France',
      faithConfession: 'Évangélique',
      maritalStatus: OnboardingMaritalStatus.single,
      whyMarriage: 'Alliance',
      photoPaths: const ['/tmp/a.jpg'],
    );

    setUp(() {
      container = ProviderContainer(
        overrides: [onboardingRepositoryProvider.overrideWithValue(_OkRepo())],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('skipPhoto completes with skippedPhoto', () async {
      final c = container.read(onboardingFlowProvider.notifier);
      c.updateDraft((_) => validDraft.copyWith(clearProfilePhoto: true));
      await c.skipPhoto();
      final s = container.read(onboardingFlowProvider);
      expect(s.completedLocally, isTrue);
      expect(s.skippedPhoto, isTrue);
      expect(s.fieldErrors, isEmpty);
    });

    test('submit completes without skippedPhoto on photo step', () async {
      final c = container.read(onboardingFlowProvider.notifier);
      c.updateDraft((_) => validDraft);
      await c.submit();
      final s = container.read(onboardingFlowProvider);
      expect(s.completedLocally, isTrue);
      expect(s.skippedPhoto, isFalse);
      expect(s.fieldErrors, isEmpty);
    });

    test('clearProfilePhoto clears path via updateDraft', () {
      final c = container.read(onboardingFlowProvider.notifier);
      c.updateDraft((d) => d.copyWith(profilePhotoPath: '/tmp/photo.jpg'));
      c.clearProfilePhoto();
      expect(
        container.read(onboardingFlowProvider).draft.profilePhotoPath,
        isNull,
      );
    });

    test(
      'submit on empty draft does not complete and keeps step 0 errors',
      () async {
        final c = container.read(onboardingFlowProvider.notifier);
        await c.submit();
        final s = container.read(onboardingFlowProvider);
        expect(s.completedLocally, isFalse);
        expect(s.currentStep, 0);
        expect(s.fieldErrors['gender'], isNotNull);
        expect(s.fieldErrors['birthDate'], isNotNull);
        expect(s.fieldErrors['country'], isNotNull);
      },
    );

    test('skipPhoto on empty draft does not complete', () async {
      final c = container.read(onboardingFlowProvider.notifier);
      await c.skipPhoto();
      final s = container.read(onboardingFlowProvider);
      expect(s.completedLocally, isFalse);
      expect(s.skippedPhoto, isFalse);
      expect(s.fieldErrors, isNotEmpty);
    });

    test('updateDraft clears only resolved field errors', () {
      final c = container.read(onboardingFlowProvider.notifier);
      c.updateDraft(
        (d) => d.copyWith(
          gender: OnboardingGender.woman,
          birthDate: DateTime(1995, 1, 1),
          country: 'France',
        ),
      );
      expect(c.next(), isTrue);
      expect(c.next(), isFalse);
      expect(
        container.read(onboardingFlowProvider).fieldErrors.keys,
        containsAll(['faithConfession', 'maritalStatus', 'whyMarriage']),
      );
      c.updateDraft((d) => d.copyWith(faithConfession: 'Évangélique'));
      final errors = container.read(onboardingFlowProvider).fieldErrors;
      expect(errors.containsKey('faithConfession'), isFalse);
      expect(errors['maritalStatus'], isNotNull);
      expect(errors['whyMarriage'], isNotNull);
    });
  });
}
