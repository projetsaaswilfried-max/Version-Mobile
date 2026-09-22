import 'dart:async';

import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/features/discover/domain/entities/discover_candidates_page.dart';
import 'package:agapeo/features/discover/domain/entities/discover_profile.dart';
import 'package:agapeo/features/discover/domain/entities/discover_profile_detail.dart';
import 'package:agapeo/features/discover/domain/entities/discover_query.dart';
import 'package:agapeo/features/discover/domain/entities/visitor_context.dart';
import 'package:agapeo/features/discover/domain/filtering/filter_discover_profiles.dart';
import 'package:agapeo/features/discover/domain/repositories/discover_repository.dart';
import 'package:agapeo/features/discover/domain/scoring/compatibility_traits.dart';

class FakeDiscoverRepository implements DiscoverRepository {
  FakeDiscoverRepository({
    Result<VisitorContext>? visitor,
    Result<List<DiscoverProfile>>? candidates,
    Result<DiscoverProfileDetail>? detail,
    Result<void>? recordView,
    this.pendingDetail,
  }) : visitor =
           visitor ??
           const Ok(
             VisitorContext(
               id: 'visitor-1',
               gender: 'MALE',
               isVerified: true,
               subscriptionStatus: 'FREE',
               traits: CompatibilityTraits(),
             ),
           ),
       candidates = candidates ?? const Ok([]),
       detail = detail ?? const Err(ServerFailure()),
       recordView = recordView ?? const Ok(null);

  Result<VisitorContext> visitor;
  Result<List<DiscoverProfile>> candidates;
  var fetchCandidatesCalls = 0;
  final fetchCandidatesOffsets = <int>[];
  final fetchCandidatesSearches = <String?>[];
  final fetchCandidatesQueries = <DiscoverQuery>[];
  /// Par défaut, une seule page — `hasMore: false`. Les tests de pagination
  /// peuvent le surcharger pour simuler un pool serveur plus grand.
  bool candidatesHasMore = false;
  Result<Set<String>> likedProfileIds = const Ok(<String>{});
  Result<Set<String>> favoritedProfileIds = const Ok(<String>{});
  Result<DiscoverProfileDetail> detail;
  Result<void> recordView;
  Completer<Result<DiscoverProfileDetail>>? pendingDetail;
  final fetchDetailIds = <String>[];
  final recordViewIds = <String>[];
  final isLikedIds = <String>[];
  final likeIds = <String>[];
  final unlikeIds = <String>[];
  Result<bool> isLiked = const Ok(false);
  Result<void> like = const Ok(null);
  Result<void> unlike = const Ok(null);
  final isFavoritedIds = <String>[];
  final favoriteIds = <String>[];
  final unfavoriteIds = <String>[];
  Result<bool> isFavorited = const Ok(false);
  Result<void> favorite = const Ok(null);
  Result<void> unfavorite = const Ok(null);
  Result<void> sendInvitationResult = const Ok(null);
  final sendInvitationCalls = <({String profileId, String? message})>[];

  @override
  Future<Result<VisitorContext>> fetchVisitor() async => visitor;

  @override
  Future<Result<DiscoverCandidatesPage>> fetchCandidates({
    required int offset,
    required int limit,
    DiscoverQuery query = const DiscoverQuery(),
  }) async {
    fetchCandidatesCalls++;
    fetchCandidatesOffsets.add(offset);
    fetchCandidatesSearches.add(query.search);
    fetchCandidatesQueries.add(query);
    return switch (candidates) {
      Ok(:final value) => Ok(
        DiscoverCandidatesPage(
          profiles: filterDiscoverProfiles(value, query),
          hasMore: candidatesHasMore,
        ),
      ),
      Err(:final failure) => Err(failure),
    };
  }

  @override
  Future<Result<Set<String>>> fetchLikedProfileIds() async => likedProfileIds;

  @override
  Future<Result<Set<String>>> fetchFavoritedProfileIds() async =>
      favoritedProfileIds;

  @override
  Future<Result<DiscoverProfileDetail>> fetchProfileDetail(
    String profileId,
  ) async {
    fetchDetailIds.add(profileId);
    final pending = pendingDetail;
    if (pending != null) {
      pendingDetail = null;
      return pending.future;
    }
    return detail;
  }

  @override
  Future<Result<void>> recordProfileView(String viewedProfileId) async {
    recordViewIds.add(viewedProfileId);
    return recordView;
  }

  @override
  Future<Result<bool>> isProfileLiked(String profileId) async {
    isLikedIds.add(profileId);
    return isLiked;
  }

  @override
  Future<Result<void>> likeProfile(String profileId) async {
    likeIds.add(profileId);
    return like;
  }

  @override
  Future<Result<void>> unlikeProfile(String profileId) async {
    unlikeIds.add(profileId);
    return unlike;
  }

  @override
  Future<Result<bool>> isProfileFavorited(String profileId) async {
    isFavoritedIds.add(profileId);
    return isFavorited;
  }

  @override
  Future<Result<void>> favoriteProfile(String profileId) async {
    favoriteIds.add(profileId);
    return favorite;
  }

  @override
  Future<Result<void>> unfavoriteProfile(String profileId) async {
    unfavoriteIds.add(profileId);
    return unfavorite;
  }

  @override
  Future<Result<void>> sendInvitation({
    required String profileId,
    String? message,
  }) async {
    sendInvitationCalls.add((profileId: profileId, message: message));
    return sendInvitationResult;
  }
}

DiscoverProfile fakeDiscoverProfile(
  String id, {
  String displayName = 'Léa Martin',
  int? age = 28,
  String? city = 'Paris',
  String? photoUrl,
  bool isVerified = true,
  String? gender = 'FEMALE',
  CompatibilityTraits traits = const CompatibilityTraits(),
}) {
  return DiscoverProfile(
    id: id,
    displayName: displayName,
    age: age,
    city: city,
    photoUrl: photoUrl,
    isVerified: isVerified,
    gender: gender,
    isComplete: true,
    traits: traits,
  );
}
