import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/onboarding_draft.dart';
import '../entities/onboarding_submit_payload.dart';
import '../repositories/onboarding_repository.dart';

class FinishWithoutVerification {
  const FinishWithoutVerification(this._repo);

  final OnboardingRepository _repo;

  Future<Result<void>> call(OnboardingDraft draft) async {
    final payload = OnboardingSubmitPayload.tryFromDraft(draft);
    if (payload == null) {
      return const Err(
        ValidationFailure('Profil incomplet ou genre non supporté.'),
      );
    }
    return _repo.finishWithoutVerification(payload);
  }
}
