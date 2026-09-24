import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:agapeo/features/auth/presentation/google/google_sign_in_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/auth_test_fakes.dart';

void main() {
  late ProviderContainer container;
  late FakeAuthRepository repo;

  setUp(() {
    repo = FakeAuthRepository(
      signInWithGoogleResult: const Ok(
        AuthSession(id: '1', email: 'a@b.co'),
      ),
    );
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() => container.dispose());

  GoogleSignInController controller() =>
      container.read(googleSignInControllerProvider.notifier);

  test(
    'signIn establishes a session synchronously (native flow, no browser, '
    'no deep link) and lets the caller navigate',
    () async {
      final c = controller();

      await c.signIn();

      expect(repo.signInWithGoogleCalled, isTrue);
      expect(c.state.isLoading, isFalse);
      expect(c.state.succeeded, isTrue);
      expect(c.state.email, 'a@b.co');
      expect(c.state.formError, isNull);
    },
  );

  test('a failure sets formError and resets isLoading', () async {
    repo = FakeAuthRepository(
      signInWithGoogleResult: const Err(
        UnauthorizedFailure('Connexion Google annulée.'),
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
    expect(c.state.formError, 'Connexion Google annulée.');
  });

  test('a second signIn call while loading is a no-op', () async {
    final c = controller();

    final first = c.signIn();
    await c.signIn();
    await first;

    // Only one real attempt happened — a second concurrent tap while the
    // first was still in flight was a no-op.
    expect(repo.signInWithGoogleCallCount, 1);
  });
}
