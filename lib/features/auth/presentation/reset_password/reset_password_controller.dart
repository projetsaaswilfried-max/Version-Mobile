import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../di/auth_providers.dart';
import '../../domain/entities/auth_session.dart';
import 'reset_password_state.dart';

class ResetPasswordController extends Notifier<ResetPasswordState> {
  @override
  ResetPasswordState build() => const ResetPasswordState();

  void setPassword(String value) {
    final errors = Map<String, String>.from(state.fieldErrors)
      ..remove('password');
    state = state.copyWith(
      password: value,
      fieldErrors: errors,
      clearFormError: true,
      succeeded: false,
    );
  }

  void setPasswordConfirm(String value) {
    final errors = Map<String, String>.from(state.fieldErrors)
      ..remove('passwordConfirm');
    state = state.copyWith(
      passwordConfirm: value,
      fieldErrors: errors,
      clearFormError: true,
      succeeded: false,
    );
  }

  Future<void> submit() async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      fieldErrors: const {},
      clearFormError: true,
      succeeded: false,
    );

    final result = await ref.read(updatePasswordProvider)(
      password: state.password,
      passwordConfirm: state.passwordConfirm,
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
}

final resetPasswordControllerProvider =
    NotifierProvider.autoDispose<ResetPasswordController, ResetPasswordState>(
      ResetPasswordController.new,
    );
