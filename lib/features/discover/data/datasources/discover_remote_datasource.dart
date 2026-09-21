class DiscoverVisitorRaw {
  const DiscoverVisitorRaw({
    required this.profile,
    required this.subscriptionStatus,
  });

  final Map<String, dynamic> profile;
  final String subscriptionStatus;
}

abstract class DiscoverRemoteDataSource {
  Future<DiscoverVisitorRaw> fetchVisitorRaw();

  Future<List<Map<String, dynamic>>> fetchCandidateRows({
    required int offset,
    required int limit,
    String? search,
  });

  Future<Set<String>> fetchLikedProfileIds();

  Future<Set<String>> fetchFavoritedProfileIds();

  Future<Map<String, dynamic>> fetchProfileDetailRow(String profileId);

  Future<void> recordProfileView(String viewedProfileId);

  Future<bool> isProfileLiked(String profileId);

  Future<void> likeProfile(String profileId);

  Future<void> unlikeProfile(String profileId);

  Future<bool> isProfileFavorited(String profileId);

  Future<void> favoriteProfile(String profileId);

  Future<void> unfavoriteProfile(String profileId);

  Future<int> countMonthlyInvitations();

  Future<void> sendInvitation({required String profileId, String? message});
}
