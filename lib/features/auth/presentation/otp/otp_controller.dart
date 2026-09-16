import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../di/auth_providers.dart';
import '../../domain/entities/auth_session.dart';
import 'otp_state.dart';

class OtpController extends Notifier<OtpState> {
  OtpController({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static const _resendCooldown = Duration(seconds: 60);

  final DateTime Function() _clock;

  @override
  OtpState build() => const OtpState();

  bool get canResend {
    final until = state.resendAllowedAt;
    if (until == null) return true;
    return !_clock().isBefore(until);
  }

  void setOtp(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final otp = digits.length > 6 ? digits.substring(0, 6) : digits;
    final errors = Map<String, String>.from(state.fieldErrors)..remove('otp');
    state = state.copyWith(
      otp: otp,
      fieldErrors: errors,
      formError: null,
      succeeded: false,
    );
  }

  Future<void> submit({required String email}) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      fieldErrors: const {},
      formError: null,
      succeeded: false,
    );

    final result = await ref.read(verifyEmailOtpProvider)(
      email: email,
      token: state.otp,
    );

    switch (result) {
      case Ok<AuthSession>():
        state = state.copyWith(isLoading: false, succeeded: true);
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

/// autoDispose: le code saisi ne doit pas survivre à la fermeture de
/// l'écran (ni à une déconnexion).
final otpControllerProvider =
    NotifierProvider.autoDispose<OtpController, OtpState>(
      () => OtpController(),
    );
