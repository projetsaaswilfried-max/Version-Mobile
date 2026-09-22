import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/discover/di/discover_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/discover_test_fakes.dart';

void main() {
  test('likeDiscoverProfileProvider forwards to repository', () async {
    final repo = FakeDiscoverRepository();
    final container = ProviderContainer(
      overrides: [discoverRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(likeDiscoverProfileProvider)('p-like');

    expect(repo.likeIds, ['p-like']);
  });

  test('unlikeDiscoverProfileProvider forwards to repository', () async {
    final repo = FakeDiscoverRepository();
    final container = ProviderContainer(
      overrides: [discoverRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(unlikeDiscoverProfileProvider)('p-un');

    expect(repo.unlikeIds, ['p-un']);
  });

  test('sendDiscoverInvitationProvider forwards to repository', () async {
    final repo = FakeDiscoverRepository();
    final container = ProviderContainer(
      overrides: [discoverRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(sendDiscoverInvitationProvider)(
      profileId: 'p-invite',
      message: 'Salut',
    );

    expect(repo.sendInvitationCalls, [
      (profileId: 'p-invite', message: 'Salut'),
    ]);
  });

  test('isDiscoverProfileLikedProvider forwards to repository', () async {
    final repo = FakeDiscoverRepository()..isLiked = const Ok(true);
    final container = ProviderContainer(
      overrides: [discoverRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final result = await container.read(isDiscoverProfileLikedProvider)(
      'p-check',
    );

    expect(repo.isLikedIds, ['p-check']);
    expect(result, isA<Ok<bool>>());
    expect((result as Ok<bool>).value, isTrue);
  });

  test('favoriteDiscoverProfileProvider forwards to repository', () async {
    final repo = FakeDiscoverRepository();
    final container = ProviderContainer(
      overrides: [discoverRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(favoriteDiscoverProfileProvider)('p-fav');

    expect(repo.favoriteIds, ['p-fav']);
  });

  test('unfavoriteDiscoverProfileProvider forwards to repository', () async {
    final repo = FakeDiscoverRepository();
    final container = ProviderContainer(
      overrides: [discoverRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(unfavoriteDiscoverProfileProvider)('p-un');

    expect(repo.unfavoriteIds, ['p-un']);
  });

  test('isDiscoverProfileFavoritedProvider forwards to repository', () async {
    final repo = FakeDiscoverRepository()..isFavorited = const Ok(true);
    final container = ProviderContainer(
      overrides: [discoverRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final result = await container.read(isDiscoverProfileFavoritedProvider)(
      'p-check',
    );

    expect(repo.isFavoritedIds, ['p-check']);
    expect(result, isA<Ok<bool>>());
    expect((result as Ok<bool>).value, isTrue);
  });
}
