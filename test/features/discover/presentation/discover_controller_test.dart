import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/discover/di/discover_providers.dart';
import 'package:agapeo/features/discover/domain/entities/discover_query.dart';
import 'package:agapeo/features/discover/domain/entities/visitor_context.dart';
import 'package:agapeo/features/discover/domain/scoring/compatibility_traits.dart';
import 'package:agapeo/features/discover/presentation/discover_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/discover_test_fakes.dart';

void main() {
  late ProviderContainer container;
  late FakeDiscoverRepository repo;

  Future<void> pumpMicrotasks() => Future<void>.delayed(Duration.zero);

  setUp(() {
    repo = FakeDiscoverRepository(
      candidates: Ok([
        for (var i = 0; i < 20; i++)
          fakeDiscoverProfile('p${i.toString().padLeft(2, '0')}'),
      ]),
    );
    container = ProviderContainer(
      overrides: [discoverRepositoryProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() => container.dispose());

  test('load initial page on build', () async {
    container.listen(discoverControllerProvider, (_, _) {});
    await pumpMicrotasks();

    final state = container.read(discoverControllerProvider);
    expect(state.isInitialLoading, isFalse);
    expect(state.expired, isFalse);
    expect(state.recommended, hasLength(3));
    expect(state.others, hasLength(12));
    expect(state.hasMoreOthers, isTrue);
    expect(state.errorMessage, isNull);
  });

  test('refresh replaces lists', () async {
    container.listen(discoverControllerProvider, (_, _) {});
    await pumpMicrotasks();
    final firstReco = container
        .read(discoverControllerProvider)
        .recommended
        .map((p) => p.id)
        .toList();

    repo.candidates = Ok([
      for (var i = 0; i < 20; i++)
        fakeDiscoverProfile(
          'n${i.toString().padLeft(2, '0')}',
          displayName: 'Naomie',
        ),
    ]);
    await container.read(discoverControllerProvider.notifier).refresh();

    final state = container.read(discoverControllerProvider);
    expect(state.recommended.map((p) => p.id).toList(), isNot(firstReco));
    expect(state.recommended.every((p) => p.id.startsWith('n')), isTrue);
    expect(state.isRefreshing, isFalse);
  });

  test('loadMore appends others without refetching candidates', () async {
    container.listen(discoverControllerProvider, (_, _) {});
    await pumpMicrotasks();
    final firstOthers = container
        .read(discoverControllerProvider)
        .others
        .map((p) => p.id)
        .toSet();
    expect(repo.fetchCandidatesCalls, 1);

    repo.candidates = Ok([
      for (var i = 0; i < 20; i++)
        fakeDiscoverProfile('z${i.toString().padLeft(2, '0')}'),
    ]);
    await container.read(discoverControllerProvider.notifier).loadMore();

    final state = container.read(discoverControllerProvider);
    expect(repo.fetchCandidatesCalls, 1);
    expect(state.others.length, greaterThan(12));
    expect(state.hasMoreOthers, isFalse);
    expect(
      state.others.skip(12).every((p) => !firstOthers.contains(p.id)),
      isTrue,
    );
    expect(state.others.every((p) => p.id.startsWith('p')), isTrue);
  });

  test('loadMore paginates the filtered list', () async {
    repo.candidates = Ok([
      for (var i = 0; i < 20; i++)
        fakeDiscoverProfile(
          'p${i.toString().padLeft(2, '0')}',
          displayName: 'Alice $i',
          traits: CompatibilityTraits(
            country: i < 16 ? 'France' : 'Sénégal',
          ),
        ),
    ]);
    repo.candidatesHasMore = true;
    container.listen(discoverControllerProvider, (_, _) {});
    await pumpMicrotasks();

    await container
        .read(discoverControllerProvider.notifier)
        .applyQuery(const DiscoverQuery(country: 'France'));

    var state = container.read(discoverControllerProvider);
    expect(state.recommended, isEmpty);
    expect(state.others, isNotEmpty);
    expect(
      state.others.every((p) => p.traits.country == 'France'),
      isTrue,
    );
    expect(repo.fetchCandidatesCalls, 2);
    expect(repo.fetchCandidatesQueries.last.country, 'France');
    expect(state.hasMoreOthers, isTrue);

    await container.read(discoverControllerProvider.notifier).loadMore();
    state = container.read(discoverControllerProvider);
    expect(state.others.every((p) => p.traits.country == 'France'), isTrue);
    expect(repo.fetchCandidatesCalls, 3);
  });

  test('initial error sets errorMessage', () async {
    repo.visitor = const Err(NetworkFailure('offline'));
    container.listen(discoverControllerProvider, (_, _) {});
    await pumpMicrotasks();

    final state = container.read(discoverControllerProvider);
    expect(state.errorMessage, isNotNull);
    expect(state.recommended, isEmpty);
    expect(state.isInitialLoading, isFalse);
  });

  test(
    'EXPIRED behaves like FREE - real cards, premium sheet offered (D42)',
    () async {
      repo.visitor = const Ok(
        VisitorContext(
          id: 'visitor-1',
          gender: 'MALE',
          isVerified: true,
          subscriptionStatus: 'EXPIRED',
          traits: CompatibilityTraits(),
        ),
      );
      container.listen(discoverControllerProvider, (_, _) {});
      await pumpMicrotasks();

      final state = container.read(discoverControllerProvider);
      expect(state.expired, isTrue);
      expect(state.recommended, hasLength(3));
      expect(state.others, isNotEmpty);
      expect(state.subscriptionStatus, 'EXPIRED');
      expect(state.shouldOfferPremiumSheet, isTrue);
    },
  );

  test('FREE visitor flags enable premium sheet offer', () async {
    container.listen(discoverControllerProvider, (_, _) {});
    await pumpMicrotasks();

    final state = container.read(discoverControllerProvider);
    expect(state.subscriptionStatus, 'FREE');
    expect(state.visitorVerified, isTrue);
    expect(state.shouldOfferPremiumSheet, isTrue);
  });

  test('applyQuery filters recommended and others after reload', () async {
    repo.candidates = Ok([
      fakeDiscoverProfile(
        'p01',
        displayName: 'Alice',
        traits: const CompatibilityTraits(country: 'France'),
      ),
      fakeDiscoverProfile(
        'p02',
        displayName: 'Béatrice',
        traits: const CompatibilityTraits(country: 'Sénégal'),
      ),
      for (var i = 3; i <= 20; i++)
        fakeDiscoverProfile(
          'p${i.toString().padLeft(2, '0')}',
          displayName: 'Alice $i',
          traits: const CompatibilityTraits(country: 'France'),
        ),
    ]);
    container.listen(discoverControllerProvider, (_, _) {});
    await pumpMicrotasks();

    await container
        .read(discoverControllerProvider.notifier)
        .applyQuery(const DiscoverQuery(country: 'Sénégal'));

    final state = container.read(discoverControllerProvider);
    expect(state.query.country, 'Sénégal');
    expect(state.query.isEmpty, isFalse);
    expect(state.recommended, isEmpty);
    expect(state.others.map((p) => p.id), ['p02']);
    expect(repo.fetchCandidatesCalls, 2);
  });

  test('clearQuery restores unfiltered lists', () async {
    repo.candidates = Ok([
      fakeDiscoverProfile(
        'p01',
        displayName: 'Alice',
        traits: const CompatibilityTraits(country: 'France'),
      ),
      fakeDiscoverProfile(
        'p02',
        displayName: 'Béatrice',
        traits: const CompatibilityTraits(country: 'Sénégal'),
      ),
      for (var i = 3; i <= 20; i++)
        fakeDiscoverProfile(
          'p${i.toString().padLeft(2, '0')}',
          displayName: 'Alice $i',
          traits: const CompatibilityTraits(country: 'France'),
        ),
    ]);
    container.listen(discoverControllerProvider, (_, _) {});
    await pumpMicrotasks();

    await container
        .read(discoverControllerProvider.notifier)
        .applyQuery(const DiscoverQuery(country: 'Sénégal'));
    await container.read(discoverControllerProvider.notifier).clearQuery();

    final state = container.read(discoverControllerProvider);
    expect(state.query.isEmpty, isTrue);
    expect(state.recommended, hasLength(3));
    expect(state.others, hasLength(12));
  });

  test(
    'applyQuery with search text queries the repository directly, '
    'finding profiles beyond the already-loaded pool',
    () async {
      repo.candidates = Ok([
        fakeDiscoverProfile('p01', displayName: 'Alice'),
        fakeDiscoverProfile('p02', displayName: 'Béatrice'),
      ]);
      container.listen(discoverControllerProvider, (_, _) {});
      await pumpMicrotasks();
      expect(
        container
            .read(discoverControllerProvider)
            .others
            .map((p) => p.displayName),
        isNot(contains('Luc')),
      );

      // "Luc" existe côté serveur mais n'a jamais été chargé localement —
      // reproduit le bug remonté en test manuel : chercher un nom hors du
      // vivier déjà en mémoire ne trouvait jamais rien.
      repo.candidates = Ok([
        fakeDiscoverProfile('p01', displayName: 'Alice'),
        fakeDiscoverProfile('p02', displayName: 'Béatrice'),
        fakeDiscoverProfile('p99', displayName: 'Luc'),
      ]);

      await container
          .read(discoverControllerProvider.notifier)
          .applyQuery(const DiscoverQuery(search: 'Luc'));

      final state = container.read(discoverControllerProvider);
      expect(state.others.map((p) => p.displayName), ['Luc']);
      expect(state.recommended, isEmpty);
      expect(repo.fetchCandidatesSearches, contains('Luc'));
    },
  );

  test(
    'clearQuery after a search restores the cached feed without a new fetch',
    () async {
      repo.candidates = Ok([
        fakeDiscoverProfile('p01', displayName: 'Alice'),
        fakeDiscoverProfile('p02', displayName: 'Béatrice'),
        for (var i = 3; i <= 6; i++)
          fakeDiscoverProfile('p0$i', displayName: 'Filler $i'),
      ]);
      container.listen(discoverControllerProvider, (_, _) {});
      await pumpMicrotasks();

      await container
          .read(discoverControllerProvider.notifier)
          .applyQuery(const DiscoverQuery(search: 'Béatrice'));
      expect(
        container.read(discoverControllerProvider).others.map((p) => p.id),
        ['p02'],
      );
      final callsAfterSearch = repo.fetchCandidatesCalls;

      await container.read(discoverControllerProvider.notifier).clearQuery();

      final state = container.read(discoverControllerProvider);
      expect(state.query.isEmpty, isTrue);
      final visible = [
        ...state.recommended,
        ...state.others,
      ].map((p) => p.id);
      expect(visible, containsAll(['p01', 'p02']));
      expect(repo.fetchCandidatesCalls, callsAfterSearch);
    },
  );

  test('toggleLike flips isLiked and calls the repository', () async {
    container.listen(discoverControllerProvider, (_, _) {});
    await pumpMicrotasks();
    final id = container.read(discoverControllerProvider).others.first.id;

    final ok = await container
        .read(discoverControllerProvider.notifier)
        .toggleLike(id);

    expect(ok, isTrue);
    expect(repo.likeIds, [id]);
    final state = container.read(discoverControllerProvider);
    expect(state.others.firstWhere((p) => p.id == id).isLiked, isTrue);

    await container.read(discoverControllerProvider.notifier).toggleLike(id);
    expect(repo.unlikeIds, [id]);
    expect(
      container
          .read(discoverControllerProvider)
          .others
          .firstWhere((p) => p.id == id)
          .isLiked,
      isFalse,
    );
  });

  test('toggleLike leaves state untouched when the repository fails', () async {
    container.listen(discoverControllerProvider, (_, _) {});
    await pumpMicrotasks();
    final id = container.read(discoverControllerProvider).others.first.id;
    repo.like = const Err(NetworkFailure('offline'));

    final ok = await container
        .read(discoverControllerProvider.notifier)
        .toggleLike(id);

    expect(ok, isFalse);
    expect(
      container
          .read(discoverControllerProvider)
          .others
          .firstWhere((p) => p.id == id)
          .isLiked,
      isFalse,
    );
  });

  test('toggleFavorite flips isFavorited and calls the repository', () async {
    container.listen(discoverControllerProvider, (_, _) {});
    await pumpMicrotasks();
    final id = container.read(discoverControllerProvider).others.first.id;

    final ok = await container
        .read(discoverControllerProvider.notifier)
        .toggleFavorite(id);

    expect(ok, isTrue);
    expect(repo.favoriteIds, [id]);
    expect(
      container
          .read(discoverControllerProvider)
          .others
          .firstWhere((p) => p.id == id)
          .isFavorited,
      isTrue,
    );
  });
}
