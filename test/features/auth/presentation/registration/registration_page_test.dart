import 'package:agapeo/core/config/app_environment.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_text_field.dart';
import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/domain/entities/auth_deep_link_result.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:agapeo/features/auth/domain/repositories/auth_repository.dart';
import 'package:agapeo/features/auth/presentation/otp/otp_page.dart';
import 'package:agapeo/features/auth/presentation/registration/registration_controller.dart';
import 'package:agapeo/features/auth/presentation/registration/registration_page.dart';
import 'package:agapeo/features/onboarding/presentation/profile_onboarding/onboarding_flow_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  AuthSession? get currentSession => null;

  @override
  Stream<AuthSession?> get authStateChanges => const Stream.empty();

  @override
  Future<Result<AuthSession>> signInWithPassword({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<Result<void>> signUp({
    required String email,
    required String password,
    required String firstName,
    String? lastName,
  }) async => const Ok(null);

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
  Future<Result<void>> signInWithGoogle() =>
      throw UnimplementedError();

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
  setUpAll(() {
    try {
      AppEnvironment.init();
    } catch (_) {}
  });

  testWidgets('shows registration fields, legal links and Google', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const RegistrationPage(),
        ),
      ),
    );

    expect(find.text('Créer un compte'), findsWidgets);
    expect(find.text('Rejoins Agapeo pour des rencontres sincères.'), findsOneWidget);
    expect(find.byType(AppTextField), findsNWidgets(5));
    expect(find.text('Prénom'), findsOneWidget);
    expect(find.text('Nom (optionnel)'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('Confirmer le mot de passe'), findsOneWidget);
    expect(find.textContaining('conditions générales d\'utilisation'), findsOneWidget);
    expect(find.textContaining('charte d\'éthique'), findsOneWidget);
    expect(find.text('CGU'), findsNothing);
    expect(find.byType(Checkbox), findsOneWidget);
    expect(find.text('Continuer avec Google'), findsOneWidget);
    expect(find.text('toi@email.com'), findsNothing);
  });

  testWidgets(
    'success without Supabase opens profile onboarding (not OTP)',
    (tester) async {
      expect(AppEnvironment.current.hasSupabase, isFalse);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const RegistrationPage(),
          ),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(RegistrationPage)),
      );
      final controller = container.read(registrationControllerProvider.notifier);
      controller.setFirstName('Jean');
      controller.setEmail('a@b.co');
      controller.setPassword('Abcdefg1');
      controller.setPasswordConfirm('Abcdefg1');
      controller.setAcceptedTerms(true);
      controller.setAcceptedCharter(true);

      await controller.submit();
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingFlowPage), findsOneWidget);
      expect(find.byType(OtpPage), findsNothing);
      expect(find.text('Informations essentielles'), findsOneWidget);
    },
  );
}
