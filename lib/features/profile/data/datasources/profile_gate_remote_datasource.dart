abstract class ProfileGateRemoteDataSource {
  Future<
      ({
        bool isSuspended,
        String subscriptionStatus,
        bool onboardingCompleted,
      })> fetchGateRaw();
}
