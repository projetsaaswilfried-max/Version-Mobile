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
    expect(OnboardingValidators.canGoNext(0, const OnboardingDraft()), isFalse);
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

  test('step 1 requires confession, marital, whyMarriage', () {
    expect(OnboardingValidators.canGoNext(1, const OnboardingDraft()), isFalse);
    expect(
      OnboardingValidators.canGoNext(
        1,
        const OnboardingDraft(
          faithConfession: 'Protestante',
          maritalStatus: OnboardingMaritalStatus.single,
          whyMarriage: 'Pour bâtir une famille dans la foi.',
        ),
      ),
      isTrue,
    );
  });

  test('step 2 hobbies is required for canGoNext', () {
    expect(
      OnboardingValidators.canGoNext(2, const OnboardingDraft()),
      isFalse,
    );
    expect(
      OnboardingValidators.canGoNext(
        2,
        const OnboardingDraft(hobbies: ['Randonnée']),
      ),
      isTrue,
    );
  });

  test('other gender is invalid on essentials', () {
    final errors = OnboardingValidators.errorsForStep(
      0,
      OnboardingDraft(
        gender: OnboardingGender.other,
        birthDate: adult,
        country: 'France',
      ),
    );
    expect(errors['gender'], isNotNull);
  });

  test('errorsForSubmit replays steps 0 then 1', () {
    expect(
      OnboardingValidators.errorsForSubmit(const OnboardingDraft()),
      containsPair('gender', 'Choisis ton genre.'),
    );
    expect(
      OnboardingValidators.firstInvalidStep(
        OnboardingDraft(
          gender: OnboardingGender.woman,
          birthDate: adult,
          country: 'France',
        ),
      ),
      1,
    );
  });
}
