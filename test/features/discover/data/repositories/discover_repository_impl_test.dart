import 'package:agapeo/core/error/exceptions.dart';
import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/discover/data/datasources/discover_remote_datasource.dart';
import 'package:agapeo/features/discover/data/repositories/discover_repository_impl.dart';
import 'package:agapeo/features/discover/di/discover_providers.dart';
import 'package:agapeo/features/discover/domain/entities/discover_candidates_page.dart';
import 'package:agapeo/features/discover/domain/entities/discover_profile_detail.dart';
import 'package:agapeo/features/discover/domain/entities/visitor_context.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRemote implements DiscoverRemoteDataSource {
  Object? visitorError;
  Object? candidatesError;
  DiscoverVisitorRaw visitor = const DiscoverVisitorRaw(
    profile: {
      'id': 'visitor-1',
      'first_name': 'Paul',
      'last_name': 'Durand',
      'gender': 'MALE',
      'birth_date': '1990-01-01',
      'city': 'Lyon',
      'country': 'FR',
      'photo_verification_status': 'VERIFIED',
      'church_denomination': 'catholique',
      'why_marriage': 'Oui',
    },
    subscriptionStatus: 'FREE',
  );
  List<Map<String, dynamic>> candidates = const [];
  int? lastCandidatesOffset;
  int? lastCandidatesLimit;
  Set<String> likedProfileIds = const {};
  Object? likedProfileIdsError;
  Set<String> favoritedProfileIds = const {};
  Object? favoritedProfileIdsError;
  Map<String, dynamic>? detailRow;
  Object? detailError;
  Object? recordError;
  String? recordedViewId;
  bool liked = false;
  Object? isLikedError;
  Object? likeError;
  Object? unlikeError;
  String? isLikedProfileId;
  String? likedProfileId;
  String? unlikedProfileId;
  bool favorited = false;
  Object? isFavoritedError;
  Object? favoriteError;
  Object? unfavoriteError;
  String? isFavoritedProfileId;
  String? favoritedProfileId;
  String? unfavoritedProfileId;
  int monthlyInvitationCount = 0;
  Object? countError;
  Object? sendError;
  String? sentProfileId;
  String? sentMessage;

  @override
  Future<DiscoverVisitorRaw> fetchVisitorRaw() async {
    if (visitorError != null) throw visitorError!;
    return visitor;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCandidateRows({
    required int offset,
    required int limit,
    String? search,
  }) async {
    lastCandidatesOffset = offset;
    lastCandidatesLimit = limit;
    if (candidatesError != null) throw candidatesError!;
    return candidates;
  }

  @override
  Future<Set<String>> fetchLikedProfileIds() async {
    if (likedProfileIdsError != null) throw likedProfileIdsError!;
    return likedProfileIds;
  }

  @override
  Future<Set<String>> fetchFavoritedProfileIds() async {
    if (favoritedProfileIdsError != null) throw favoritedProfileIdsError!;
    return favoritedProfileIds;
  }

  @override
  Future<Map<String, dynamic>> fetchProfileDetailRow(String profileId) async {
    if (detailError != null) throw detailError!;
    if (detailRow == null) {
      throw const ServerException('Profil introuvable.');
    }
    return detailRow!;
  }

  @override
  Future<void> recordProfileView(String viewedProfileId) async {
    if (recordError != null) throw recordError!;
    recordedViewId = viewedProfileId;
  }

  @override
  Future<bool> isProfileLiked(String profileId) async {
    if (isLikedError != null) throw isLikedError!;
    isLikedProfileId = profileId;
    return liked;
  }

  @override
  Future<void> likeProfile(String profileId) async {
    if (likeError != null) throw likeError!;
    likedProfileId = profileId;
  }

  @override
  Future<void> unlikeProfile(String profileId) async {
    if (unlikeError != null) throw unlikeError!;
    unlikedProfileId = profileId;
  }

  @override
  Future<bool> isProfileFavorited(String profileId) async {
    if (isFavoritedError != null) throw isFavoritedError!;
    isFavoritedProfileId = profileId;
    return favorited;
  }

  @override
  Future<void> favoriteProfile(String profileId) async {
    if (favoriteError != null) throw favoriteError!;
    favoritedProfileId = profileId;
  }

  @override
  Future<void> unfavoriteProfile(String profileId) async {
    if (unfavoriteError != null) throw unfavoriteError!;
    unfavoritedProfileId = profileId;
  }

  @override
  Future<int> countMonthlyInvitations() async {
    if (countError != null) throw countError!;
    return monthlyInvitationCount;
  }

  @override
  Future<void> sendInvitation({
    required String profileId,
    String? message,
  }) async {
    if (sendError != null) throw sendError!;
    sentProfileId = profileId;
    sentMessage = message;
  }
}

void main() {
  test('maps datasource exceptions to Failure', () async {
    final repo = DiscoverRepositoryImpl(
      _FakeRemote()..visitorError = const NetworkException('offline'),
    );
    final result = await repo.fetchVisitor();
    expect(result, isA<Err<VisitorContext>>());
    expect((result as Err).failure, isA<NetworkFailure>());
  });

  test('reads EXPIRED from profile_restricted', () async {
    final remote = _FakeRemote();
    remote.visitor = DiscoverVisitorRaw(
      profile: remote.visitor.profile,
      subscriptionStatus: 'EXPIRED',
    );
    final result = await DiscoverRepositoryImpl(remote).fetchVisitor();
    expect(result, isA<Ok<VisitorContext>>());
    final visitor = (result as Ok<VisitorContext>).value;
    expect(visitor.isExpired, isTrue);
    expect(visitor.subscriptionStatus, 'EXPIRED');
    expect(visitor.id, 'visitor-1');
    expect(visitor.gender, 'MALE');
    expect(visitor.isVerified, isTrue);
  });

  test('skips candidate rows without id', () async {
    final remote = _FakeRemote()
      ..candidates = [
        {
          'first_name': 'SansId',
          'photo_verification_status': 'VERIFIED',
          'gender': 'FEMALE',
          'birth_date': '1998-01-01',
          'country': 'FR',
          'church_denomination': 'x',
          'why_marriage': 'y',
        },
        {
          'id': 'ok-1',
          'first_name': 'Léa',
          'last_name': 'M',
          'photo_url': 'https://cdn.example/lea.jpg',
          'photo_verification_status': 'VERIFIED',
          'gender': 'FEMALE',
          'birth_date': '1998-01-01',
          'city': 'Paris',
          'country': 'FR',
          'church_denomination': 'x',
          'why_marriage': 'y',
        },
      ];
    final result = await DiscoverRepositoryImpl(
      remote,
    ).fetchCandidates(offset: 0, limit: 60);
    expect(result, isA<Ok<DiscoverCandidatesPage>>());
    final page = (result as Ok<DiscoverCandidatesPage>).value;
    expect(page.profiles, hasLength(1));
    expect(page.profiles.single.id, 'ok-1');
    expect(page.profiles.single.displayName, 'Léa M');
    expect(page.profiles.single.photoUrl, 'https://cdn.example/lea.jpg');
    expect(page.hasMore, isFalse);
    expect(remote.lastCandidatesOffset, 0);
    expect(remote.lastCandidatesLimit, 60);
  });

  test('hasMore is true when the raw row count fills the requested page', () async {
    final remote = _FakeRemote()
      ..candidates = [
        for (var i = 0; i < 3; i++)
          {
            'id': 'ok-$i',
            'first_name': 'Léa',
            'photo_verification_status': 'VERIFIED',
            'gender': 'FEMALE',
            'birth_date': '1998-01-01',
            'country': 'FR',
            'church_denomination': 'x',
            'why_marriage': 'y',
          },
      ];
    final result = await DiscoverRepositoryImpl(
      remote,
    ).fetchCandidates(offset: 0, limit: 3);
    final page = (result as Ok<DiscoverCandidatesPage>).value;
    expect(page.hasMore, isTrue);
  });

  test('maps candidate fetch errors', () async {
    final result = await DiscoverRepositoryImpl(
      _FakeRemote()..candidatesError = const ServerException('boom'),
    ).fetchCandidates(offset: 0, limit: 60);
    expect(result, isA<Err<DiscoverCandidatesPage>>());
    expect((result as Err).failure, isA<ServerFailure>());
  });

  test('maps profile detail row including all hydrated photos', () async {
    final remote = _FakeRemote()
      ..detailRow = {
        'id': 'p-detail',
        'first_name': 'Léa',
        'last_name': 'Martin',
        'birth_date': '1998-03-10',
        'city': 'Paris',
        'photo_verification_status': 'VERIFIED',
        'church_denomination': 'protestant',
        'spiritual_engagement': 'pratique',
        'why_marriage': 'Pour construire',
        'values': ['foi'],
        'hobbies': ['course'],
        'profile_photos': [
          {'url': 'https://cdn.example/a.jpg', 'is_primary': false},
          {'url': 'https://cdn.example/b.jpg', 'is_primary': true},
        ],
      };
    final result = await DiscoverRepositoryImpl(
      remote,
      clock: () => DateTime.utc(2026, 9, 18),
    ).fetchProfileDetail('p-detail');
    expect(result, isA<Ok<DiscoverProfileDetail>>());
    final detail = (result as Ok<DiscoverProfileDetail>).value;
    expect(detail.id, 'p-detail');
    expect(detail.displayName, 'Léa Martin');
    expect(detail.age, 28);
    expect(detail.city, 'Paris');
    expect(detail.isVerified, isTrue);
    expect(detail.confession, 'protestant');
    expect(detail.spiritualEngagement, 'pratique');
    expect(detail.whyMarriage, 'Pour construire');
    expect(detail.values, ['foi']);
    expect(detail.hobbies, ['course']);
    expect(detail.photoUrls, [
      'https://cdn.example/b.jpg',
      'https://cdn.example/a.jpg',
    ]);
  });

  test('maps missing profile detail to ServerFailure', () async {
    final result = await DiscoverRepositoryImpl(
      _FakeRemote()..detailError = const ServerException('Profil introuvable.'),
    ).fetchProfileDetail('missing');
    expect(result, isA<Err<DiscoverProfileDetail>>());
    expect((result as Err).failure, isA<ServerFailure>());
  });

  test('recordProfileView delegates to the datasource', () async {
    final remote = _FakeRemote();
    final result = await DiscoverRepositoryImpl(
      remote,
    ).recordProfileView('viewed-9');
    expect(result, isA<Ok<void>>());
    expect(remote.recordedViewId, 'viewed-9');
  });

  test('maps recordProfileView errors', () async {
    final result = await DiscoverRepositoryImpl(
      _FakeRemote()..recordError = const NetworkException('offline'),
    ).recordProfileView('viewed-9');
    expect(result, isA<Err<void>>());
    expect((result as Err).failure, isA<NetworkFailure>());
  });

  test(
    'UnconfiguredDiscoverRepository returns Err for detail and view',
    () async {
      const repo = UnconfiguredDiscoverRepository();
      final detail = await repo.fetchProfileDetail('p1');
      final view = await repo.recordProfileView('p1');
      expect(detail, isA<Err<DiscoverProfileDetail>>());
      expect(view, isA<Err<void>>());
      expect((detail as Err).failure, UnconfiguredDiscoverRepository.failure);
      expect((view as Err).failure, UnconfiguredDiscoverRepository.failure);
    },
  );

  test(
    'UnconfiguredDiscoverRepository returns Err for like operations',
    () async {
      const repo = UnconfiguredDiscoverRepository();
      final liked = await repo.isProfileLiked('p1');
      final like = await repo.likeProfile('p1');
      final unlike = await repo.unlikeProfile('p1');
      expect(liked, isA<Err<bool>>());
      expect(like, isA<Err<void>>());
      expect(unlike, isA<Err<void>>());
      expect((liked as Err).failure, UnconfiguredDiscoverRepository.failure);
    },
  );

  test(
    'UnconfiguredDiscoverRepository returns Err for favorite operations',
    () async {
      const repo = UnconfiguredDiscoverRepository();
      final favorited = await repo.isProfileFavorited('p1');
      final favorite = await repo.favoriteProfile('p1');
      final unfavorite = await repo.unfavoriteProfile('p1');
      expect(favorited, isA<Err<bool>>());
      expect(favorite, isA<Err<void>>());
      expect(unfavorite, isA<Err<void>>());
      expect(
        (favorited as Err).failure,
        UnconfiguredDiscoverRepository.failure,
      );
    },
  );

  test(
    'UnconfiguredDiscoverRepository returns Err for invitation operations',
    () async {
      const repo = UnconfiguredDiscoverRepository();
      final count = await repo.countMonthlyInvitations();
      final send = await repo.sendInvitation(profileId: 'p1');
      expect(count, isA<Err<int>>());
      expect(send, isA<Err<void>>());
      expect((count as Err).failure, UnconfiguredDiscoverRepository.failure);
      expect((send as Err).failure, UnconfiguredDiscoverRepository.failure);
    },
  );

  test('countMonthlyInvitations returns Ok from datasource', () async {
    final remote = _FakeRemote()..monthlyInvitationCount = 2;
    final result = await DiscoverRepositoryImpl(
      remote,
    ).countMonthlyInvitations();
    expect(result, isA<Ok<int>>());
    expect((result as Ok<int>).value, 2);
  });

  test('maps countMonthlyInvitations errors', () async {
    final result = await DiscoverRepositoryImpl(
      _FakeRemote()..countError = const NetworkException('offline'),
    ).countMonthlyInvitations();
    expect(result, isA<Err<int>>());
    expect((result as Err).failure, isA<NetworkFailure>());
  });

  test('sendInvitation delegates profileId and message', () async {
    final remote = _FakeRemote();
    final result = await DiscoverRepositoryImpl(
      remote,
    ).sendInvitation(profileId: 'p-invite', message: 'Bonjour');
    expect(result, isA<Ok<void>>());
    expect(remote.sentProfileId, 'p-invite');
    expect(remote.sentMessage, 'Bonjour');
  });

  test('maps sendInvitation errors', () async {
    final result = await DiscoverRepositoryImpl(
      _FakeRemote()..sendError = const ServerException('rpc'),
    ).sendInvitation(profileId: 'p1');
    expect(result, isA<Err<void>>());
    expect((result as Err).failure, isA<ServerFailure>());
  });

  test('isProfileLiked returns Ok true from datasource', () async {
    final remote = _FakeRemote()..liked = true;
    final result = await DiscoverRepositoryImpl(
      remote,
    ).isProfileLiked('p-liked');
    expect(result, isA<Ok<bool>>());
    expect((result as Ok<bool>).value, isTrue);
    expect(remote.isLikedProfileId, 'p-liked');
  });

  test('isProfileLiked returns Ok false from datasource', () async {
    final result = await DiscoverRepositoryImpl(
      _FakeRemote(),
    ).isProfileLiked('p-not');
    expect(result, isA<Ok<bool>>());
    expect((result as Ok<bool>).value, isFalse);
  });

  test('maps isProfileLiked errors', () async {
    final result = await DiscoverRepositoryImpl(
      _FakeRemote()..isLikedError = const NetworkException('offline'),
    ).isProfileLiked('p1');
    expect(result, isA<Err<bool>>());
    expect((result as Err).failure, isA<NetworkFailure>());
  });

  test('likeProfile delegates to the datasource', () async {
    final remote = _FakeRemote();
    final result = await DiscoverRepositoryImpl(remote).likeProfile('p-like');
    expect(result, isA<Ok<void>>());
    expect(remote.likedProfileId, 'p-like');
  });

  test('maps likeProfile errors', () async {
    final result = await DiscoverRepositoryImpl(
      _FakeRemote()..likeError = const ServerException('boom'),
    ).likeProfile('p1');
    expect(result, isA<Err<void>>());
    expect((result as Err).failure, isA<ServerFailure>());
  });

  test('unlikeProfile delegates to the datasource', () async {
    final remote = _FakeRemote();
    final result = await DiscoverRepositoryImpl(remote).unlikeProfile('p-un');
    expect(result, isA<Ok<void>>());
    expect(remote.unlikedProfileId, 'p-un');
  });

  test('maps unlikeProfile errors', () async {
    final result = await DiscoverRepositoryImpl(
      _FakeRemote()
        ..unlikeError = const UnauthorizedException('Session expirée.'),
    ).unlikeProfile('p1');
    expect(result, isA<Err<void>>());
    expect((result as Err).failure, isA<UnauthorizedFailure>());
  });

  test('isProfileFavorited returns Ok true from datasource', () async {
    final remote = _FakeRemote()..favorited = true;
    final result = await DiscoverRepositoryImpl(
      remote,
    ).isProfileFavorited('p-fav');
    expect(result, isA<Ok<bool>>());
    expect((result as Ok<bool>).value, isTrue);
    expect(remote.isFavoritedProfileId, 'p-fav');
  });

  test('maps isProfileFavorited errors', () async {
    final result = await DiscoverRepositoryImpl(
      _FakeRemote()..isFavoritedError = const NetworkException('offline'),
    ).isProfileFavorited('p1');
    expect(result, isA<Err<bool>>());
    expect((result as Err).failure, isA<NetworkFailure>());
  });

  test('favoriteProfile delegates to the datasource', () async {
    final remote = _FakeRemote();
    final result = await DiscoverRepositoryImpl(
      remote,
    ).favoriteProfile('p-fav');
    expect(result, isA<Ok<void>>());
    expect(remote.favoritedProfileId, 'p-fav');
  });

  test('maps favoriteProfile errors', () async {
    final result = await DiscoverRepositoryImpl(
      _FakeRemote()..favoriteError = const ServerException('boom'),
    ).favoriteProfile('p1');
    expect(result, isA<Err<void>>());
    expect((result as Err).failure, isA<ServerFailure>());
  });

  test('unfavoriteProfile delegates to the datasource', () async {
    final remote = _FakeRemote();
    final result = await DiscoverRepositoryImpl(
      remote,
    ).unfavoriteProfile('p-un');
    expect(result, isA<Ok<void>>());
    expect(remote.unfavoritedProfileId, 'p-un');
  });

  test('maps unfavoriteProfile errors', () async {
    final result = await DiscoverRepositoryImpl(
      _FakeRemote()
        ..unfavoriteError = const UnauthorizedException('Session expirée.'),
    ).unfavoriteProfile('p1');
    expect(result, isA<Err<void>>());
    expect((result as Err).failure, isA<UnauthorizedFailure>());
  });
}
