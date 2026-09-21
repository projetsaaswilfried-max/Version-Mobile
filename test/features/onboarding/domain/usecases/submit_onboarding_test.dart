import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/onboarding/domain/entities/onboarding_draft.dart';
import 'package:agapeo/features/onboarding/domain/entities/onboarding_submit_payload.dart';
import 'package:agapeo/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:agapeo/features/onboarding/domain/usecases/submit_onboarding.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements OnboardingRepository {
  final calls = <String>[];
  Result<void> next = const Ok(null);

  @override
  Future<Result<void>> submit(OnboardingSubmitPayload p) async {
    calls.add('submit:${p.profilePhotoPath}');
    return next;
  }

  @override
  Future<Result<void>> finishWithoutVerification(
    OnboardingSubmitPayload p,
  ) async {
    calls.add('finish');
    return next;
  }
}

void main() {
  test('SubmitOnboarding requires photo path and delegates', () async {
    final repo = _FakeRepo();
    final uc = SubmitOnboarding(repo);
    final draft = OnboardingDraft(
      gender: OnboardingGender.woman,
      birthDate: DateTime(1995, 1, 1),
      country: 'France',
      faithConfession: 'Évangélique',
      maritalStatus: OnboardingMaritalStatus.single,
      whyMarriage: 'Alliance',
      photoPaths: const ['/tmp/a.jpg'],
    );
    final r = await uc(draft);
    expect(r, isA<Ok<void>>());
    expect(repo.calls, ['submit:/tmp/a.jpg']);
  });

  test('SubmitOnboarding fails without photo', () async {
    final uc = SubmitOnboarding(_FakeRepo());
    final draft = OnboardingDraft(
      gender: OnboardingGender.woman,
      birthDate: DateTime(1995, 1, 1),
      country: 'France',
      faithConfession: 'Évangélique',
      maritalStatus: OnboardingMaritalStatus.single,
      whyMarriage: 'Alliance',
    );
    final r = await uc(draft);
    expect(r, isA<Err<void>>());
  });
}
