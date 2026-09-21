import '../../../../core/error/result.dart';
import '../entities/onboarding_submit_payload.dart';

abstract class OnboardingRepository {
  Future<Result<void>> submit(OnboardingSubmitPayload payload);
  Future<Result<void>> finishWithoutVerification(OnboardingSubmitPayload payload);
}
