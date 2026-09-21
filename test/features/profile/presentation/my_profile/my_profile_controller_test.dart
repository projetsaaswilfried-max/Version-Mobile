import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/profile/di/profile_providers.dart';
import 'package:agapeo/features/profile/domain/entities/my_profile_photo.dart';
import 'package:agapeo/features/profile/presentation/my_profile/my_profile_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/profile_test_fakes.dart';

void main() {
  late ProviderContainer container;
  late FakeMyProfileRepository repo;

  Future<void> pumpMicrotasks() => Future<void>.delayed(Duration.zero);

  setUp(() {
    repo = FakeMyProfileRepository(fetchResult: Ok(fakeMyProfile()));
    container = ProviderContainer(
      overrides: [myProfileRepositoryProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() => container.dispose());

  test('loads profile on build', () async {
    container.listen(myProfileControllerProvider, (_, _) {});
    await pumpMicrotasks();
    final state = container.read(myProfileControllerProvider);
    expect(state.isInitialLoading, isFalse);
    expect(state.profile?.firstName, 'Léa');
    expect(state.profile?.denomination, 'Évangélique');
    expect(state.profile?.whyMarriage, 'Alliance');
    expect(state.profile?.maritalStatusDb, 'SINGLE_NO_CHILDREN');
    expect(state.errorMessage, isNull);
  });

  test('save returns true on Ok', () async {
    container.listen(myProfileControllerProvider, (_, _) {});
    await pumpMicrotasks();
    final ok = await container
        .read(myProfileControllerProvider.notifier)
        .save();
    expect(ok, isTrue);
    expect(repo.lastSavePhotos, isTrue);
  });

  test('updateProfile then save persists faith fields', () async {
    container.listen(myProfileControllerProvider, (_, _) {});
    await pumpMicrotasks();
    final notifier = container.read(myProfileControllerProvider.notifier);
    notifier.updateProfile(
      (p) => p.copyWith(
        denomination: 'Baptiste',
        whyMarriage: 'Pour bâtir',
        maritalStatusDb: 'DIVORCED',
      ),
    );
    final ok = await notifier.save();
    expect(ok, isTrue);
    expect(repo.saveCalls, 1);
    expect(repo.lastSavedProfile?.denomination, 'Baptiste');
    expect(repo.lastSavedProfile?.whyMarriage, 'Pour bâtir');
    expect(repo.lastSavedProfile?.maritalStatusDb, 'DIVORCED');
  });

  test('verified removePhotoAt is a no-op', () async {
    repo.fetchResult = Ok(
      fakeMyProfile(isVerified: true).copyWith(
        photos: const [
          MyProfilePhoto(id: 'p1', publicUrl: 'https://cdn/a.jpg'),
        ],
      ),
    );
    container.listen(myProfileControllerProvider, (_, _) {});
    await pumpMicrotasks();
    container.read(myProfileControllerProvider.notifier).removePhotoAt(0);
    expect(
      container.read(myProfileControllerProvider).profile?.photos,
      hasLength(1),
    );
  });
}
