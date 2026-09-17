import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../di/auth_providers.dart';
import '../../domain/entities/auth_session.dart';
import 'login_state.dart';

class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  void setEmail(String value) {
    final errors = Map<String, String>.from(state.fieldErrors)..remove('email');
    state = state.copyWith(
      email: value,
      fieldErrors: errors,
      formError: null,
      succeeded: false,
    );
  }

  void setPassword(String value) {
    final errors = Map<String, String>.from(state.fieldErrors)
      ..remove('password');
    state = state.copyWith(
      password: value,
      fieldErrors: errors,
      formError: null,
      succeeded: false,
    );
  }

  Future<void> submit() async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      fieldErrors: const {},
      formError: null,
      succeeded: false,
      emailNotConfirmed: false,
    );

    final result = await ref.read(signInWithPasswordProvider)(
      email: state.email,
      password: state.password,
    );

    switch (result) {
      case Ok<AuthSession>():
        state = state.copyWith(isLoading: false, succeeded: true);
      case Err<AuthSession>(failure: final EmailNotConfirmedFailure _):
        // The original signup code/link is necessarily stale by now (the
        // member is only here because a normal login failed) — resend it
        // ourselves and go straight to the OTP screen instead of leaving
        // them stuck on an error with a button to press.
        await ref.read(resendSignupEmailProvider)(email: state.email.trim());
        state = state.copyWith(isLoading: false, emailNotConfirmed: true);
      case Err<AuthSession>(:final failure):
        state = state.copyWith(
          isLoading: false,
          fieldErrors: failure is ValidationFailure
              ? Map<String, String>.from(failure.fieldErrors ?? const {})
              : const {},
          formError: failure.message,
        );
    }
  }
}

/// autoDispose: les identifiants saisis ne doivent pas survivre à la
/// fermeture de l'écran (ni à une déconnexion).
final loginControllerProvider =
    NotifierProvider.autoDispose<LoginController, LoginState>(
      LoginController.new,
    );
