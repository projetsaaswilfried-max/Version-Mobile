import 'package:agapeo/features/onboarding/presentation/profile_onboarding/onboarding_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final adult = DateTime(1995, 6, 15);
  final minor = DateTime(
    DateTime.now().year - 16,
    DateTime.now().month,
    DateTime.now().day,
  );

  test('O01 requires gender, adult birthDate and country', () {
    expect(
      OnboardingValidators.canGoNext(0, const OnboardingDraft()),
      isFalse,
    );
    expect(
      OnboardingValidators.canGoNext(
        0,
        OnboardingDraft(
          gender: OnboardingGender.woman,
          birthDate: adult,
          country: 'France',
        ),
      ),
      isTrue,
    );
    expect(
      OnboardingValidators.errorsForStep(
        0,
        OnboardingDraft(
          gender: OnboardingGender.man,
          birthDate: minor,
          country: 'France',
        ),
      )['birthDate'],
      isNotNull,
    );
  });

  test('O02 requires at least one photo', () {
    expect(
      OnboardingValidators.canGoNext(1, const OnboardingDraft()),
      isFalse,
    );
    expect(
      OnboardingValidators.canGoNext(
        1,
        const OnboardingDraft(photoPaths: ['/tmp/a.jpg']),
      ),
      isTrue,
    );
  });

  test('O05 requires whyMarriage', () {
    expect(
      OnboardingValidators.canGoNext(4, const OnboardingDraft()),
      isFalse,
    );
    expect(
      OnboardingValidators.canGoNext(
        4,
        const OnboardingDraft(whyMarriage: 'Pour bâtir un foyer.'),
      ),
      isTrue,
    );
  });
}
