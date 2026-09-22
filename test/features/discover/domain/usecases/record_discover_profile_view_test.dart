import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/discover/domain/entities/discover_candidates_page.dart';
import 'package:agapeo/features/discover/domain/entities/discover_profile_detail.dart';
import 'package:agapeo/features/discover/domain/entities/discover_query.dart';
import 'package:agapeo/features/discover/domain/entities/visitor_context.dart';
import 'package:agapeo/features/discover/domain/repositories/discover_repository.dart';
import 'package:agapeo/features/discover/domain/usecases/record_discover_profile_view.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements DiscoverRepository {
  String? lastViewedProfileId;
  Result<void> recordResult = const Ok(null);

  @override
  Future<Result<VisitorContext>> fetchVisitor() async =>
      const Err(ServerFailure());

  @override
  Future<Result<DiscoverCandidatesPage>> fetchCandidates({
    required int offset,
    required int limit,
    DiscoverQuery query = const DiscoverQuery(),
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
  Future<Result<void>> recordProfileView(String viewedProfileId) async {
    lastViewedProfileId = viewedProfileId;
    return recordResult;
  }

  @override
  Future<Result<bool>> isProfileLiked(String profileId) async =>
      const Ok(false);

  @override
  Future<Result<void>> likeProfile(String profileId) async =>
      const Ok(null);

  @override
  Future<Result<void>> unlikeProfile(String profileId) async =>
      const Ok(null);

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
  Future<Result<void>> sendInvitation({
    required String profileId,
    String? message,
  }) async =>
      const Ok(null);
}

void main() {
  test('RecordDiscoverProfileView forwards to repository', () async {
    final repo = _FakeRepo();

    await RecordDiscoverProfileView(repo)('p1');

    expect(repo.lastViewedProfileId, 'p1');
  });

  test('RecordDiscoverProfileView forwards repository Err', () async {
    final repo = _FakeRepo()..recordResult = const Err(NetworkFailure());

    final result = await RecordDiscoverProfileView(repo)('p1');

    expect(result, isA<Err<void>>());
    expect((result as Err).failure, isA<NetworkFailure>());
  });
}
