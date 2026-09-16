import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../di/auth_providers.dart';
import '../../domain/entities/auth_session.dart';
import 'verify_email_state.dart';

class VerifyEmailController extends Notifier<VerifyEmailState> {
  VerifyEmailController({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const _resendCooldown = Duration(seconds: 60);

  final DateTime Function() _clock;

  @override
  VerifyEmailState build() => const VerifyEmailState();

  bool get canResend {
    final until = state.resendAllowedAt;
    if (until == null) return true;
    return !_clock().isBefore(until);
  }

  Future<void> confirm({
    required String email,
    required String password,
  }) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, formError: null, succeeded: false);

    final result = await ref.read(signInWithPasswordProvider)(
      email: email,
      password: password,
    );

    switch (result) {
      case Ok<AuthSession>():
        state = state.copyWith(isLoading: false, succeeded: true);
      case Err<AuthSession>(:final failure):
        state = state.copyWith(isLoading: false, formError: failure.message);
    }
  }

  Future<void> resend({required String email}) async {
    if (!canResend || state.isResending) return;

    final allowedAt = _clock().add(_resendCooldown);
    state = state.copyWith(
      isResending: true,
      formError: null,
      resendAllowedAt: allowedAt,
    );

    final result = await ref.read(resendSignupEmailProvider)(email: email);

    switch (result) {
      case Ok<void>():
        state = state.copyWith(isResending: false);
      case Err<void>(:final failure):
        state = state.copyWith(isResending: false, formError: failure.message);
    }
  }
}

/// autoDispose: l'état ne doit pas survivre à la fermeture de l'écran
/// (ni à une déconnexion).
final verifyEmailControllerProvider =
    NotifierProvider.autoDispose<VerifyEmailController, VerifyEmailState>(
      () => VerifyEmailController(),
    );
