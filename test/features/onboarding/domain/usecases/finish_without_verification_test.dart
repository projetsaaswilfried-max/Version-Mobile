import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/onboarding/domain/entities/onboarding_draft.dart';
import 'package:agapeo/features/onboarding/domain/entities/onboarding_submit_payload.dart';
import 'package:agapeo/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:agapeo/features/onboarding/domain/usecases/finish_without_verification.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements OnboardingRepository {
  final calls = <String>[];
  Result<void> next = const Ok(null);

  @override
  Future<Result<void>> submit(OnboardingSubmitPayload p) async {
    calls.add('submit');
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
  test('FinishWithoutVerification allows missing photo', () async {
    final repo = _FakeRepo();
    final r = await FinishWithoutVerification(repo)(
      OnboardingDraft(
        gender: OnboardingGender.man,
        birthDate: DateTime(1990, 5, 5),
        country: 'Sénégal',
        faithConfession: 'Catholique',
        maritalStatus: OnboardingMaritalStatus.divorced,
        whyMarriage: 'Famille',
      ),
    );
    expect(r, isA<Ok<void>>());
    expect(repo.calls, ['finish']);
  });
}
