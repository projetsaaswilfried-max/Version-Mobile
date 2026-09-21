import '../../../../core/error/result.dart';
import '../entities/discover_candidates_page.dart';
import '../entities/discover_profile_detail.dart';
import '../entities/visitor_context.dart';

abstract class DiscoverRepository {
  Future<Result<VisitorContext>> fetchVisitor();
  Future<Result<DiscoverCandidatesPage>> fetchCandidates({
    required int offset,
    required int limit,
    String? search,
  });
  Future<Result<Set<String>>> fetchLikedProfileIds();
  Future<Result<Set<String>>> fetchFavoritedProfileIds();
  Future<Result<DiscoverProfileDetail>> fetchProfileDetail(String profileId);
  Future<Result<void>> recordProfileView(String viewedProfileId);
  Future<Result<bool>> isProfileLiked(String profileId);
  Future<Result<void>> likeProfile(String profileId);
  Future<Result<void>> unlikeProfile(String profileId);
  Future<Result<bool>> isProfileFavorited(String profileId);
  Future<Result<void>> favoriteProfile(String profileId);
  Future<Result<void>> unfavoriteProfile(String profileId);
  Future<Result<int>> countMonthlyInvitations();
  Future<Result<void>> sendInvitation({
    required String profileId,
    String? message,
  });
}
