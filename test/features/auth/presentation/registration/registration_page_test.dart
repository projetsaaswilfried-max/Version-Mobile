import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_text_field.dart';
import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:agapeo/features/auth/domain/repositories/auth_repository.dart';
import 'package:agapeo/features/auth/presentation/otp/otp_page.dart';
import 'package:agapeo/features/auth/presentation/registration/registration_controller.dart';
import 'package:agapeo/features/auth/presentation/registration/registration_page.dart';
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
  Future<Result<void>> signOut() => throw UnimplementedError();
}

void main() {
  testWidgets('shows registration fields, legal links and no Google', (
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

    expect(find.byType(AppTextField), findsNWidgets(5));
    expect(find.text('Prénom'), findsOneWidget);
    expect(find.text('Nom (optionnel)'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('Confirmer le mot de passe'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
    expect(find.text('CGU'), findsWidgets);
    expect(find.text("Charte d'éthique"), findsWidgets);
    expect(find.byType(Checkbox), findsNWidgets(2));
    expect(find.text('Google'), findsNothing);
  });

  testWidgets('success replaces with OtpPage without showing password', (
    tester,
  ) async {
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

    expect(find.byType(OtpPage), findsOneWidget);
    expect(find.text('a@b.co'), findsOneWidget);
    expect(find.text('Abcdefg1'), findsNothing);
  });
}
