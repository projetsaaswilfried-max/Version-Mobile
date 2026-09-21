import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/discover/domain/entities/discover_candidates_page.dart';
import 'package:agapeo/features/discover/domain/entities/discover_profile_detail.dart';
import 'package:agapeo/features/discover/domain/entities/visitor_context.dart';
import 'package:agapeo/features/discover/domain/repositories/discover_repository.dart';
import 'package:agapeo/features/discover/domain/usecases/is_discover_profile_liked.dart';
import 'package:agapeo/features/discover/domain/usecases/like_discover_profile.dart';
import 'package:agapeo/features/discover/domain/usecases/unlike_discover_profile.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements DiscoverRepository {
  String? lastLikeId;
  String? lastUnlikeId;
  String? lastIsLikedId;
  Result<bool> isLikedResult = const Ok(false);
  Result<void> likeResult = const Ok(null);
  Result<void> unlikeResult = const Ok(null);

  @override
  Future<Result<VisitorContext>> fetchVisitor() async =>
      const Err(ServerFailure());

  @override
  Future<Result<DiscoverCandidatesPage>> fetchCandidates({
    required int offset,
    required int limit,
    String? search,
  }) async => const Ok(DiscoverCandidatesPage(profiles: [], hasMore: false));

  @override
  Future<Result<Set<String>>> fetchLikedProfileIds() async =>
      const Ok(<String>{});

  @override
  Future<Result<Set<String>>> fetchFavoritedProfileIds() async =>
      const Ok(<String>{});

  @override
  Future<Result<DiscoverProfileDetail>> fetchProfileDetail(
    String profileId,
  ) async => const Err(ServerFailure());

  @override
  Future<Result<void>> recordProfileView(String viewedProfileId) async =>
      const Ok(null);

  @override
  Future<Result<bool>> isProfileLiked(String profileId) async {
    lastIsLikedId = profileId;
    return isLikedResult;
  }

  @override
  Future<Result<void>> likeProfile(String profileId) async {
    lastLikeId = profileId;
    return likeResult;
  }

  @override
  Future<Result<void>> unlikeProfile(String profileId) async {
    lastUnlikeId = profileId;
    return unlikeResult;
  }

  @override
  Future<Result<bool>> isProfileFavorited(String profileId) async =>
      const Ok(false);

  @override
  Future<Result<void>> favoriteProfile(String profileId) async =>
      const Ok(null);

  @override
  Future<Result<void>> unfavoriteProfile(String profileId) async =>
      const Ok(null);

  @override
  Future<Result<int>> countMonthlyInvitations() async => const Ok(0);

  @override
  Future<Result<void>> sendInvitation({
    required String profileId,
    String? message,
  }) async =>
      const Ok(null);
}

void main() {
  test('LikeDiscoverProfile forwards to repository', () async {
    final repo = _FakeRepo();

    await LikeDiscoverProfile(repo)('p1');

    expect(repo.lastLikeId, 'p1');
  });

  test('LikeDiscoverProfile forwards repository Err', () async {
    final repo = _FakeRepo()..likeResult = const Err(NetworkFailure());

    final result = await LikeDiscoverProfile(repo)('p1');

    expect(result, isA<Err<void>>());
    expect((result as Err).failure, isA<NetworkFailure>());
  });

  test('UnlikeDiscoverProfile forwards to repository', () async {
    final repo = _FakeRepo();

    await UnlikeDiscoverProfile(repo)('p2');

    expect(repo.lastUnlikeId, 'p2');
  });

  test('IsDiscoverProfileLiked forwards to repository', () async {
    final repo = _FakeRepo()..isLikedResult = const Ok(true);

    final result = await IsDiscoverProfileLiked(repo)('p3');

    expect(repo.lastIsLikedId, 'p3');
    expect(result, isA<Ok<bool>>());
    expect((result as Ok).value, isTrue);
  });
}
