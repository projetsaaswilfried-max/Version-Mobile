import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../di/auth_providers.dart';
import 'forgot_password_state.dart';

class ForgotPasswordController extends Notifier<ForgotPasswordState> {
  static const genericSuccessMessage =
      'Si un compte existe pour cette adresse, tu recevras un email avec la suite.';

  @override
  ForgotPasswordState build() => const ForgotPasswordState();

  void setEmail(String value) {
    final errors = Map<String, String>.from(state.fieldErrors)..remove('email');
    state = state.copyWith(
      email: value,
      fieldErrors: errors,
      formError: null,
      successMessage: null,
    );
  }

  Future<void> submit() async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      fieldErrors: const {},
      formError: null,
      successMessage: null,
    );

    final result = await ref.read(requestPasswordResetProvider)(
      email: state.email,
    );

    switch (result) {
      case Ok<void>():
        state = state.copyWith(
          isLoading: false,
          successMessage: genericSuccessMessage,
        );
      case Err<void>(:final failure):
        if (failure is NetworkFailure) {
          state = state.copyWith(isLoading: false, formError: failure.message);
        } else if (failure is ValidationFailure) {
          state = state.copyWith(
            isLoading: false,
            fieldErrors: Map<String, String>.from(
              failure.fieldErrors ?? const {},
            ),
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            successMessage: genericSuccessMessage,
          );
        }
    }
  }
}

/// autoDispose: l'email saisi ne doit pas survivre à la fermeture de
/// l'écran (ni à une déconnexion).
final forgotPasswordControllerProvider =
    NotifierProvider.autoDispose<ForgotPasswordController, ForgotPasswordState>(
      ForgotPasswordController.new,
    );
