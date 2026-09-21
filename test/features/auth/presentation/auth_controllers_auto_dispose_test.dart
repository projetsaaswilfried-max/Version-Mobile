import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/core/theme/app_spacing.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/domain/entities/auth_deep_link_result.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:agapeo/features/auth/domain/repositories/auth_repository.dart';
import 'package:agapeo/features/auth/presentation/forgot_password/forgot_password_controller.dart';
import 'package:agapeo/features/auth/presentation/login/login_controller.dart';
import 'package:agapeo/features/auth/presentation/login/login_page.dart';
import 'package:agapeo/features/auth/presentation/otp/otp_controller.dart';
import 'package:agapeo/features/auth/presentation/registration/registration_controller.dart';
import 'package:agapeo/features/feed/di/feed_providers.dart';
import 'package:agapeo/features/home/presentation/home_shell_page.dart';
import 'package:agapeo/features/notifications/di/notifications_providers.dart';
import 'package:agapeo/features/profile/di/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/auth_test_fakes.dart';
import '../../../helpers/feed_test_fakes.dart';
import '../../../helpers/notifications_test_fakes.dart';
import '../../../helpers/profile_test_fakes.dart';

class _FakeAuthRepository implements AuthRepository {
  int signInCalls = 0;

  @override
  AuthSession? get currentSession => null;

  @override
  Stream<AuthSession?> get authStateChanges => const Stream.empty();

  @override
  Future<Result<AuthSession>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    return Ok(AuthSession(id: 'u1', email: email));
  }

  @override
  Future<Result<void>> signUp({
    required String email,
    required String password,
    required String firstName,
    String? lastName,
  }) => throw UnimplementedError();

  @override
  Future<Result<AuthSession>> verifyEmailOtp({
    required String email,
    required String token,
  }) => throw UnimplementedError();

  @override
  Future<Result<void>> resendSignupEmail({required String email}) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> requestPasswordReset({required String email}) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<Result<AuthSession>> updatePassword({required String password}) =>
      throw UnimplementedError();

  @override
  Future<Result<AuthDeepLinkResult>> handleAuthDeepLink(Uri uri) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> signOut() async => const Ok(null);
}

void main() {
  test('tous les controllers auth sont autoDispose', () {
    expect(loginControllerProvider.isAutoDispose, isTrue);
    expect(registrationControllerProvider.isAutoDispose, isTrue);
    expect(otpControllerProvider.isAutoDispose, isTrue);
    expect(forgotPasswordControllerProvider.isAutoDispose, isTrue);
  });

  test('le mot de passe ne survit pas à la fermeture de l\'écran', () async {
    final repo = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    // Écran monté : un listener garde le controller en vie.
    final subscription = container.listen(loginControllerProvider, (_, _) {});
    container.read(loginControllerProvider.notifier)
      ..setEmail('a@b.co')
      ..setPassword('Secret12');
    expect(container.read(loginControllerProvider).password, 'Secret12');

    // Écran démonté (logout) : plus de listener, l'état est jeté.
    subscription.close();
    await Future<void>.delayed(Duration.zero);

    expect(container.read(loginControllerProvider).password, isEmpty);
    expect(container.read(loginControllerProvider).email, isEmpty);
  });

  test('le code OTP ne survit pas à la fermeture de l\'écran', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final subscription = container.listen(otpControllerProvider, (_, _) {});
    container.read(otpControllerProvider.notifier).setOtp('123456');
    expect(container.read(otpControllerProvider).otp, '123456');

    subscription.close();
    await Future<void>.delayed(Duration.zero);

    expect(container.read(otpControllerProvider).otp, isEmpty);
  });

  testWidgets(
    'après login puis logout, le nouveau controller repart vide et ne peut '
    'pas resoumettre le mot de passe',
    (tester) async {
      final repo = _FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          profileGateRepositoryProvider.overrideWithValue(
            FakeProfileGateRepository(),
          ),
          feedRepositoryProvider.overrideWithValue(FakeFeedRepository()),
          notificationsRepositoryProvider.overrideWithValue(
            FakeNotificationsRepository(),
          ),
          profileFieldsRepositoryProvider.overrideWithValue(
            FakeProfileFieldsRepository(
              result: Ok(fakeProfileFieldsSnapshot()),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(theme: AppTheme.light, home: const LoginPage()),
        ),
      );

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'a@b.co');
      await tester.enterText(fields.at(1), 'Secret12');
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeShellPage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
      expect(repo.signInCalls, 1);

      await tester.tap(find.byTooltip('Profil'));
      await tester.pumpAndSettle();
      final logout = find.text('Déconnexion');
      await tester.scrollUntilVisible(
        logout,
        AppSpacing.xxxl,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(logout);
      await tester.pumpAndSettle();
      expect(find.text('Se déconnecter ?'), findsOneWidget);
      await tester.tap(find.text('Déconnexion').last);
      await tester.pumpAndSettle();

      // Réouverture de l'écran de connexion : le listener simule le widget
      // qui remonte, donc un controller neuf.
      final subscription = container.listen(loginControllerProvider, (_, _) {});
      addTearDown(subscription.close);

      final controller = container.read(loginControllerProvider.notifier);
      expect(controller.state.password, isEmpty);
      expect(controller.state.email, isEmpty);
      expect(controller.state.succeeded, isFalse);

      await controller.submit();

      expect(controller.state.fieldErrors['password'], isNotNull);
      expect(repo.signInCalls, 1);
    },
  );
}
