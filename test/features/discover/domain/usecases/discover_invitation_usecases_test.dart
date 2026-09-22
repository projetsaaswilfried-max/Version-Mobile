import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/discover/domain/entities/discover_candidates_page.dart';
import 'package:agapeo/features/discover/domain/entities/discover_profile_detail.dart';
import 'package:agapeo/features/discover/domain/entities/discover_query.dart';
import 'package:agapeo/features/discover/domain/entities/visitor_context.dart';
import 'package:agapeo/features/discover/domain/repositories/discover_repository.dart';
import 'package:agapeo/features/discover/domain/usecases/send_discover_invitation.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements DiscoverRepository {
  Result<void> sendResult = const Ok(null);
  String? lastSendProfileId;
  String? lastSendMessage;

  @override
  Future<Result<void>> sendInvitation({
    required String profileId,
    String? message,
  }) async {
    lastSendProfileId = profileId;
    lastSendMessage = message;
    return sendResult;
  }

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
  Future<Result<bool>> isProfileFavorited(String profileId) async =>
      const Ok(false);

  @override
  Future<Result<void>> favoriteProfile(String profileId) async =>
      const Ok(null);

  @override
  Future<Result<void>> unfavoriteProfile(String profileId) async =>
      const Ok(null);
}

void main() {
  test('SendDiscoverInvitation forwards profileId and message', () async {
    final repo = _FakeRepo();

    await SendDiscoverInvitation(repo)(
      profileId: 'p-invite',
      message: 'Bonjour',
    );

    expect(repo.lastSendProfileId, 'p-invite');
    expect(repo.lastSendMessage, 'Bonjour');
  });

  test('SendDiscoverInvitation forwards repository Err', () async {
    final repo = _FakeRepo()..sendResult = const Err(ServerFailure());

    final result = await SendDiscoverInvitation(repo)(profileId: 'p1');

    expect(result, isA<Err<void>>());
    expect((result as Err).failure, isA<ServerFailure>());
  });
}
