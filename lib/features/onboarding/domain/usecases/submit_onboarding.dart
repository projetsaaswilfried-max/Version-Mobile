import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/onboarding_draft.dart';
import '../entities/onboarding_submit_payload.dart';
import '../repositories/onboarding_repository.dart';

class SubmitOnboarding {
  const SubmitOnboarding(this._repo);

  final OnboardingRepository _repo;

  Future<Result<void>> call(OnboardingDraft draft) async {
    final payload = OnboardingSubmitPayload.tryFromDraft(draft);
    if (payload == null) {
      return const Err(
        ValidationFailure('Profil incomplet ou genre non supporté.'),
      );
    }
    if (payload.profilePhotoPath == null ||
        payload.profilePhotoPath!.isEmpty) {
      return const Err(ValidationFailure('Ajoute une photo pour terminer.'));
    }
    return _repo.submit(payload);
  }
}
