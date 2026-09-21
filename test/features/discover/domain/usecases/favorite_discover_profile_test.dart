import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/discover/domain/entities/discover_candidates_page.dart';
import 'package:agapeo/features/discover/domain/entities/discover_profile_detail.dart';
import 'package:agapeo/features/discover/domain/entities/visitor_context.dart';
import 'package:agapeo/features/discover/domain/repositories/discover_repository.dart';
import 'package:agapeo/features/discover/domain/usecases/favorite_discover_profile.dart';
import 'package:agapeo/features/discover/domain/usecases/is_discover_profile_favorited.dart';
import 'package:agapeo/features/discover/domain/usecases/unfavorite_discover_profile.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements DiscoverRepository {
  String? lastFavoriteId;
  String? lastUnfavoriteId;
  String? lastIsFavoritedId;
  Result<bool> isFavoritedResult = const Ok(false);
  Result<void> favoriteResult = const Ok(null);
  Result<void> unfavoriteResult = const Ok(null);

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
  Future<Result<bool>> isProfileLiked(String profileId) async =>
      const Ok(false);

  @override
  Future<Result<void>> likeProfile(String profileId) async => const Ok(null);

  @override
  Future<Result<void>> unlikeProfile(String profileId) async =>
      const Ok(null);

  @override
  Future<Result<bool>> isProfileFavorited(String profileId) async {
    lastIsFavoritedId = profileId;
    return isFavoritedResult;
  }

  @override
  Future<Result<void>> favoriteProfile(String profileId) async {
    lastFavoriteId = profileId;
    return favoriteResult;
  }

  @override
  Future<Result<void>> unfavoriteProfile(String profileId) async {
    lastUnfavoriteId = profileId;
    return unfavoriteResult;
  }

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
  test('FavoriteDiscoverProfile forwards to repository', () async {
    final repo = _FakeRepo();

    await FavoriteDiscoverProfile(repo)('p1');

    expect(repo.lastFavoriteId, 'p1');
  });

  test('FavoriteDiscoverProfile forwards repository Err', () async {
    final repo = _FakeRepo()..favoriteResult = const Err(NetworkFailure());

    final result = await FavoriteDiscoverProfile(repo)('p1');

    expect(result, isA<Err<void>>());
    expect((result as Err).failure, isA<NetworkFailure>());
  });

  test('UnfavoriteDiscoverProfile forwards to repository', () async {
    final repo = _FakeRepo();

    await UnfavoriteDiscoverProfile(repo)('p2');

    expect(repo.lastUnfavoriteId, 'p2');
  });

  test('IsDiscoverProfileFavorited forwards to repository', () async {
    final repo = _FakeRepo()..isFavoritedResult = const Ok(true);

    final result = await IsDiscoverProfileFavorited(repo)('p3');

    expect(repo.lastIsFavoritedId, 'p3');
    expect(result, isA<Ok<bool>>());
    expect((result as Ok).value, isTrue);
  });
}
