import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/discover/domain/entities/discover_candidates_page.dart';
import 'package:agapeo/features/discover/domain/entities/discover_page.dart';
import 'package:agapeo/features/discover/domain/entities/discover_profile.dart';
import 'package:agapeo/features/discover/domain/entities/discover_profile_detail.dart';
import 'package:agapeo/features/discover/domain/entities/visitor_context.dart';
import 'package:agapeo/features/discover/domain/masking/discover_mask.dart';
import 'package:agapeo/features/discover/domain/repositories/discover_repository.dart';
import 'package:agapeo/features/discover/domain/scoring/compatibility_traits.dart';
import 'package:agapeo/features/discover/domain/usecases/get_discover_page.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDiscoverRepository implements DiscoverRepository {
  Result<VisitorContext> visitor = Ok(_visitor());
  Result<List<DiscoverProfile>> candidates = const Ok([]);
  var fetchCandidatesCalls = 0;
  final fetchCandidatesOffsets = <int>[];
  String? lastSearch;
  bool candidatesHasMore = false;
  Result<Set<String>> likedProfileIds = const Ok(<String>{});
  Result<Set<String>> favoritedProfileIds = const Ok(<String>{});

  @override
  Future<Result<VisitorContext>> fetchVisitor() async => visitor;

  @override
  Future<Result<DiscoverCandidatesPage>> fetchCandidates({
    required int offset,
    required int limit,
    String? search,
  }) async {
    fetchCandidatesCalls++;
    lastSearch = search;
    fetchCandidatesOffsets.add(offset);
    return switch (candidates) {
      Ok(:final value) =>
        Ok(DiscoverCandidatesPage(profiles: value, hasMore: candidatesHasMore)),
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
  Future<Result<void>> unlikeProfile(String profileId) async => const Ok(null);

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
  }) async => const Ok(null);
}

VisitorContext _visitor({
  String id = 'visitor-1',
  String? gender = 'MALE',
  bool isVerified = false,
  String subscriptionStatus = 'FREE',
  CompatibilityTraits traits = const CompatibilityTraits(),
}) {
  return VisitorContext(
    id: id,
    gender: gender,
    isVerified: isVerified,
    subscriptionStatus: subscriptionStatus,
    traits: traits,
  );
}

DiscoverProfile _profile(
  String id, {
  String displayName = 'Léa',
  int? age = 28,
  String? city = 'Paris',
  String? gender = 'FEMALE',
  bool isVerified = true,
  bool isStaff = false,
  bool isMatched = false,
  bool isComplete = true,
  CompatibilityTraits traits = const CompatibilityTraits(),
}) {
  return DiscoverProfile(
    id: id,
    displayName: displayName,
    age: age,
    city: city,
    isVerified: isVerified,
    gender: gender,
    isStaff: isStaff,
    isMatched: isMatched,
    isComplete: isComplete,
    traits: traits,
  );
}

List<DiscoverProfile> _eligiblePool({int count = 20}) {
  return [
    for (var i = 0; i < count; i++)
      _profile('p${i.toString().padLeft(2, '0')}'),
  ];
}

DiscoverPage _okPage(Result<DiscoverPage> result) {
  expect(result, isA<Ok<DiscoverPage>>());
  return (result as Ok<DiscoverPage>).value;
}

void main() {
  final clock = DateTime.utc(2026, 9, 18);

  test('EXPIRED returns empty page without fetching candidates', () async {
    final repo = _FakeDiscoverRepository()
      ..visitor = Ok(_visitor(subscriptionStatus: 'EXPIRED'))
      ..candidates = Ok(_eligiblePool());
    final page = _okPage(await GetDiscoverPage(repo, clock: () => clock)());

    expect(repo.fetchCandidatesCalls, 0);
    expect(page.expired, isTrue);
    expect(page.recommended, isEmpty);
    expect(page.others, isEmpty);
  });

  test('returns 3 recommended and the rest as others', () async {
    final repo = _FakeDiscoverRepository()..candidates = Ok(_eligiblePool());
    final page = _okPage(await GetDiscoverPage(repo, clock: () => clock)());

    expect(page.expired, isFalse);
    expect(page.recommended, hasLength(3));
    expect(page.others, hasLength(17));

    final recoIds = page.recommended.map((p) => p.id).toSet();
    expect(recoIds, hasLength(3));
    expect(page.others.every((p) => !recoIds.contains(p.id)), isTrue);
  });

  test(
    'ineligible candidates are excluded from recommended and others',
    () async {
      final repo = _FakeDiscoverRepository()
        ..candidates = Ok([
          _profile('ok-1'),
          _profile('ok-2'),
          _profile('ok-3'),
          _profile('ok-4'),
          _profile('staff', isStaff: true),
          _profile('matched', isMatched: true),
          _profile('unverified', isVerified: false),
          _profile('incomplete', isComplete: false),
          _profile('same-gender', gender: 'MALE'),
          _profile('no-gender', gender: null),
        ]);
      final page = _okPage(await GetDiscoverPage(repo, clock: () => clock)());

      final ids = [
        ...page.recommended.map((p) => p.id),
        ...page.others.map((p) => p.id),
      ];
      expect(ids.toSet(), {'ok-1', 'ok-2', 'ok-3', 'ok-4'});
      expect(page.recommended, hasLength(3));
      expect(page.others, hasLength(1));
    },
  );

  test('masks name city and age when visitor cannot reveal identity', () async {
    final repo = _FakeDiscoverRepository()
      ..visitor = Ok(_visitor(isVerified: false, subscriptionStatus: 'FREE'))
      ..candidates = Ok([
        _profile('ok-1', displayName: 'Léa', age: 28, city: 'Paris'),
      ]);
    final page = _okPage(await GetDiscoverPage(repo, clock: () => clock)());

    final card = page.recommended.single;
    expect(card.displayName, maskIdentity('Léa'));
    expect(card.city, maskIdentity('Paris'));
    expect(card.age, isNull);
    expect(card.ageLabel, '**');
    expect(page.visitorVerified, isFalse);
    expect(page.subscriptionStatus, 'FREE');
    expect(page.visitorTraitsIncomplete, isTrue);
  });

  test('reveals identity when visitor is verified', () async {
    final repo = _FakeDiscoverRepository()
      ..visitor = Ok(_visitor(isVerified: true, subscriptionStatus: 'FREE'))
      ..candidates = Ok([
        _profile('ok-1', displayName: 'Léa', age: 28, city: 'Paris'),
      ]);
    final page = _okPage(await GetDiscoverPage(repo, clock: () => clock)());

    final card = page.recommended.single;
    expect(card.displayName, 'Léa');
    expect(card.city, 'Paris');
    expect(card.age, 28);
    expect(card.ageLabel, '28');
  });

  test(
    'GetDiscoverPage forwards visitor Err without fetching candidates',
    () async {
      final repo = _FakeDiscoverRepository()
        ..visitor = const Err(NetworkFailure())
        ..candidates = Ok(_eligiblePool());
      final result = await GetDiscoverPage(repo, clock: () => clock)();

      expect(result, isA<Err<DiscoverPage>>());
      expect((result as Err).failure, isA<NetworkFailure>());
      expect(repo.fetchCandidatesCalls, 0);
    },
  );

  test('GetDiscoverPage forwards candidates Err', () async {
    final repo = _FakeDiscoverRepository()
      ..candidates = const Err(ServerFailure());
    final result = await GetDiscoverPage(repo, clock: () => clock)();

    expect(result, isA<Err<DiscoverPage>>());
    expect((result as Err).failure, isA<ServerFailure>());
    expect(repo.fetchCandidatesCalls, 1);
  });

  test('excludes the visitor id from recommended and others', () async {
    final repo = _FakeDiscoverRepository()
      ..visitor = Ok(_visitor(id: 'visitor-1', gender: 'MALE'))
      ..candidates = Ok([
        _profile('visitor-1', gender: 'FEMALE'),
        _profile('ok-1'),
        _profile('ok-2'),
        _profile('ok-3'),
      ]);
    final page = _okPage(await GetDiscoverPage(repo, clock: () => clock)());

    final ids = [
      ...page.recommended.map((p) => p.id),
      ...page.others.map((p) => p.id),
    ];
    expect(ids, isNot(contains('visitor-1')));
    expect(ids.toSet(), {'ok-1', 'ok-2', 'ok-3'});
  });

  test('no candidate is eligible when visitor gender is null', () async {
    final repo = _FakeDiscoverRepository()
      ..visitor = Ok(_visitor(gender: null))
      ..candidates = Ok(_eligiblePool());
    final page = _okPage(await GetDiscoverPage(repo, clock: () => clock)());

    expect(page.recommended, isEmpty);
    expect(page.others, isEmpty);
    expect(page.expired, isFalse);
  });

  test(
    'keeps identity masked for unverified visitor even with ACTIVE subscription',
    () async {
      final repo = _FakeDiscoverRepository()
        ..visitor = Ok(
          _visitor(isVerified: false, subscriptionStatus: 'ACTIVE'),
        )
        ..candidates = Ok([
          _profile('ok-1', displayName: 'Léa', age: 28, city: 'Paris'),
        ]);
      final page = _okPage(await GetDiscoverPage(repo, clock: () => clock)());

      final card = page.recommended.single;
      expect(card.displayName, maskIdentity('Léa'));
      expect(card.city, maskIdentity('Paris'));
    },
  );

  test('reveals identity when visitor is verified', () async {
    final repo = _FakeDiscoverRepository()
      ..visitor = Ok(_visitor(isVerified: true, subscriptionStatus: 'FREE'))
      ..candidates = Ok([
        _profile('ok-1', displayName: 'Léa', age: 28, city: 'Paris'),
      ]);
    final page = _okPage(await GetDiscoverPage(repo, clock: () => clock)());

    final card = page.recommended.single;
    expect(card.displayName, 'Léa');
    expect(card.city, 'Paris');
    expect(card.age, 28);
    expect(card.ageLabel, '28');
  });

  test('marks candidates as liked/favorited from the bulk fetch', () async {
    final repo = _FakeDiscoverRepository()
      ..candidates = Ok([_profile('ok-1'), _profile('ok-2')])
      ..likedProfileIds = const Ok({'ok-1'})
      ..favoritedProfileIds = const Ok({'ok-2'});
    final page = _okPage(await GetDiscoverPage(repo, clock: () => clock)());

    final all = [...page.recommended, ...page.others];
    expect(all.firstWhere((p) => p.id == 'ok-1').isLiked, isTrue);
    expect(all.firstWhere((p) => p.id == 'ok-1').isFavorited, isFalse);
    expect(all.firstWhere((p) => p.id == 'ok-2').isFavorited, isTrue);
    expect(all.firstWhere((p) => p.id == 'ok-2').isLiked, isFalse);
  });

  test('like/favorite bulk fetch failures soft-fail to unmarked', () async {
    final repo = _FakeDiscoverRepository()
      ..candidates = Ok([_profile('ok-1')])
      ..likedProfileIds = const Err(NetworkFailure('offline'))
      ..favoritedProfileIds = const Err(NetworkFailure('offline'));
    final page = _okPage(await GetDiscoverPage(repo, clock: () => clock)());

    final profile = [...page.recommended, ...page.others].single;
    expect(profile.isLiked, isFalse);
    expect(profile.isFavorited, isFalse);
  });

  test('first page requests offset 0 with the server batch size', () async {
    final repo = _FakeDiscoverRepository()..candidates = Ok(_eligiblePool());
    await GetDiscoverPage(repo, clock: () => clock)();

    expect(repo.fetchCandidatesOffsets, [0]);
  });

  test('call() propagates hasMoreCandidates from the repository', () async {
    final repo = _FakeDiscoverRepository()
      ..candidates = Ok(_eligiblePool())
      ..candidatesHasMore = true;
    final page = _okPage(await GetDiscoverPage(repo, clock: () => clock)());

    expect(page.hasMoreCandidates, isTrue);
  });

  test('more() fetches the requested offset and only fills others', () async {
    final repo = _FakeDiscoverRepository()
      ..candidates = Ok(_eligiblePool(count: 5))
      ..candidatesHasMore = true;
    final visitor = _visitor();

    final result = await GetDiscoverPage(
      repo,
      clock: () => clock,
    ).more(visitor: visitor, offset: GetDiscoverPage.serverBatchSize);

    expect(repo.fetchCandidatesOffsets, [GetDiscoverPage.serverBatchSize]);
    expect(result, isA<Ok<DiscoverMorePage>>());
    final page = (result as Ok<DiscoverMorePage>).value;
    expect(page.others, hasLength(5));
    expect(page.hasMore, isTrue);
  });

  test('more() forwards candidates Err', () async {
    final repo = _FakeDiscoverRepository()
      ..candidates = const Err(ServerFailure());
    final result = await GetDiscoverPage(
      repo,
      clock: () => clock,
    ).more(visitor: _visitor(), offset: GetDiscoverPage.serverBatchSize);

    expect(result, isA<Err<DiscoverMorePage>>());
  });
}
