import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:agapeo/features/profile/di/profile_providers.dart';
import 'package:agapeo/features/profile/presentation/hub/profile_hub_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/auth_test_fakes.dart';
import '../../../../helpers/profile_test_fakes.dart';

void main() {
  late ProviderContainer container;
  late FakeProfileFieldsRepository repo;

  Future<void> pumpMicrotasks() => Future<void>.delayed(Duration.zero);

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        profileFieldsRepositoryProvider.overrideWithValue(repo),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(
            currentSession: const AuthSession(
              id: '1',
              email: 'lea@agapeo.love',
            ),
          ),
        ),
      ],
    );
  }

  setUp(() {
    repo = FakeProfileFieldsRepository(result: Ok(fakeProfileFieldsSnapshot()));
    container = makeContainer();
  });

  tearDown(() => container.dispose());

  test('load initial hub on build', () async {
    container.listen(profileHubControllerProvider, (_, _) {});
    await pumpMicrotasks();

    final state = container.read(profileHubControllerProvider);
    expect(state.isInitialLoading, isFalse);
    expect(state.hub?.displayName, 'Léa Martin');
    expect(state.hub?.isVerified, isTrue);
    expect(state.errorMessage, isNull);
    expect(repo.fetchCalls, 1);
  });

  test('load Err exposes error without hub', () async {
    repo.result = const Err(NetworkFailure('offline'));
    container.listen(profileHubControllerProvider, (_, _) {});
    await pumpMicrotasks();

    final state = container.read(profileHubControllerProvider);
    expect(state.hub, isNull);
    expect(state.errorMessage, isNotNull);
    expect(state.isInitialLoading, isFalse);
  });

  test('retry after error reloads hub', () async {
    repo.result = const Err(NetworkFailure('offline'));
    container.listen(profileHubControllerProvider, (_, _) {});
    await pumpMicrotasks();
    expect(container.read(profileHubControllerProvider).hub, isNull);

    repo.result = Ok(fakeProfileFieldsSnapshot());
    await container.read(profileHubControllerProvider.notifier).retry();

    final state = container.read(profileHubControllerProvider);
    expect(state.hub?.displayName, 'Léa Martin');
    expect(state.errorMessage, isNull);
    expect(repo.fetchCalls, 2);
  });
}
