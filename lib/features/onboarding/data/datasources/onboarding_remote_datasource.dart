import '../../domain/entities/onboarding_submit_payload.dart';

/// Remote writes for onboarding. Column names documented in the Supabase impl.
abstract class OnboardingRemoteDataSource {
  Future<void> updateProfileFields({
    required String genderDb,
    required DateTime birthDate,
    required String country,
    required String faithConfession,
    required String maritalStatusDb,
    required String whyMarriage,
    required bool onboardingCompleted,
  });

  Future<void> uploadPhoto({
    required String localPath,
    required int slot,
    required bool isPrimary,
  });
}

extension OnboardingRemoteDataSourcePayload on OnboardingRemoteDataSource {
  Future<void> updateFromPayload(
    OnboardingSubmitPayload payload, {
    required bool onboardingCompleted,
  }) {
    return updateProfileFields(
      genderDb: payload.genderDb,
      birthDate: payload.birthDate,
      country: payload.country,
      faithConfession: payload.faithConfession,
      maritalStatusDb: payload.maritalStatusDb,
      whyMarriage: payload.whyMarriage,
      onboardingCompleted: onboardingCompleted,
    );
  }
}
