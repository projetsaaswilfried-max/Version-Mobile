import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:agapeo/features/auth/presentation/apple/apple_sign_in_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/auth_test_fakes.dart';

void main() {
  late ProviderContainer container;
  late FakeAuthRepository repo;

  setUp(() {
    repo = FakeAuthRepository(
      signInWithAppleResult: const Ok(AuthSession(id: '1', email: 'a@b.co')),
    );
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() => container.dispose());

  AppleSignInController controller() =>
      container.read(appleSignInControllerProvider.notifier);

  test(
    'signIn establishes a session synchronously (native flow) and lets '
    'the caller navigate',
    () async {
      final c = controller();

      await c.signIn();

      expect(repo.signInWithAppleCalled, isTrue);
      expect(c.state.isLoading, isFalse);
      expect(c.state.succeeded, isTrue);
      expect(c.state.email, 'a@b.co');
      expect(c.state.formError, isNull);
    },
  );

  test('a failure sets formError and resets isLoading', () async {
    repo = FakeAuthRepository(
      signInWithAppleResult: const Err(
        UnauthorizedFailure('Connexion Apple annulée.'),
      ),
    );
    container.dispose();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    final c = controller();

    await c.signIn();

    expect(c.state.isLoading, isFalse);
    expect(c.state.succeeded, isFalse);
    expect(c.state.formError, 'Connexion Apple annulée.');
  });

  test('a second signIn call while loading is a no-op', () async {
    final c = controller();

    final first = c.signIn();
    await c.signIn();
    await first;

    expect(repo.signInWithAppleCallCount, 1);
  });
}
