import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../di/auth_providers.dart';
import 'registration_state.dart';

class RegistrationController extends Notifier<RegistrationState> {
  @override
  RegistrationState build() => const RegistrationState();

  void setFirstName(String value) {
    final errors = Map<String, String>.from(state.fieldErrors)
      ..remove('firstName');
    state = state.copyWith(
      firstName: value,
      fieldErrors: errors,
      formError: null,
      succeeded: false,
    );
  }

  void setLastName(String value) {
    state = state.copyWith(lastName: value, formError: null, succeeded: false);
  }

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

  void setPasswordConfirm(String value) {
    final errors = Map<String, String>.from(state.fieldErrors)
      ..remove('passwordConfirm');
    state = state.copyWith(
      passwordConfirm: value,
      fieldErrors: errors,
      formError: null,
      succeeded: false,
    );
  }

  void setAcceptedTerms(bool value) {
    final errors = Map<String, String>.from(state.fieldErrors)
      ..remove('acceptedTerms')
      ..remove('acceptedCharter');
    state = state.copyWith(
      acceptedTerms: value,
      acceptedCharter: value,
      fieldErrors: errors,
      formError: null,
      succeeded: false,
    );
  }

  void setAcceptedCharter(bool value) {
    setAcceptedTerms(value);
  }

  Future<void> submit() async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      fieldErrors: const {},
      formError: null,
      succeeded: false,
    );

    final trimmedLastName = state.lastName.trim();
    final result = await ref.read(signUpProvider)(
      email: state.email,
      password: state.password,
      passwordConfirm: state.passwordConfirm,
      firstName: state.firstName,
      lastName: trimmedLastName.isEmpty ? null : trimmedLastName,
      acceptedTerms: state.acceptedTerms,
      acceptedCharter: state.acceptedCharter,
    );

    switch (result) {
      case Ok<void>():
        state = state.copyWith(isLoading: false, succeeded: true);
      case Err<void>(:final failure):
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
final registrationControllerProvider =
    NotifierProvider.autoDispose<RegistrationController, RegistrationState>(
      RegistrationController.new,
    );
