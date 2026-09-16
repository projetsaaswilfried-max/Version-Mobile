import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_text_field.dart';
import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/domain/entities/auth_deep_link_result.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:agapeo/features/auth/domain/repositories/auth_repository.dart';
import 'package:agapeo/features/auth/presentation/forgot_password/forgot_password_page.dart';
import 'package:agapeo/features/auth/presentation/login/login_page.dart';
import 'package:agapeo/features/auth/presentation/otp/otp_page.dart';
import 'package:agapeo/features/auth/presentation/registration/registration_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _UnconfirmedAuthRepository implements AuthRepository {
  @override
  AuthSession? get currentSession => null;

  @override
  Stream<AuthSession?> get authStateChanges => const Stream.empty();

  @override
  Future<Result<AuthSession>> signInWithPassword({
    required String email,
    required String password,
  }) async => const Err(EmailNotConfirmedFailure('Email non confirmé.'));

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
  Future<Result<void>> signOut() => throw UnimplementedError();
}

void main() {
  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: const LoginPage()),
      ),
    );
  }

  testWidgets('shows Datify-style login fields, CTA and Google', (tester) async {
    await pumpLogin(tester);

    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('Heureux de te revoir sur Agapeo.'), findsOneWidget);
    expect(find.byType(AppTextField), findsNWidgets(2));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Mot de passe oublié ?'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
    expect(find.text('Continuer avec Google'), findsOneWidget);
    expect(find.text('CGU'), findsOneWidget);
    expect(find.text('Confidentialité'), findsOneWidget);
  });

  testWidgets('Mot de passe oublié opens forgot password', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text('Mot de passe oublié ?'));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordPage), findsOneWidget);
  });

  testWidgets('Créer un compte opens registration', (tester) async {
    await pumpLogin(tester);

    await tester.ensureVisible(find.text('Créer un compte'));
    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();

    expect(find.byType(RegistrationPage), findsOneWidget);
  });

  testWidgets(
    'unconfirmed email shows a way back to the OTP screen instead of a dead end',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              _UnconfirmedAuthRepository(),
            ),
          ],
          child: MaterialApp(theme: AppTheme.light, home: const LoginPage()),
        ),
      );

      await tester.enterText(find.byType(TextField).at(0), 'a@b.co');
      await tester.enterText(find.byType(TextField).at(1), 'Abcdefg1');
      await tester.ensureVisible(find.text('Se connecter'));
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      expect(find.text('Confirmer mon compte'), findsOneWidget);

      await tester.tap(find.text('Confirmer mon compte'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(OtpPage), findsOneWidget);
    },
  );
}
