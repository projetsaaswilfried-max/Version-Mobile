import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../di/auth_providers.dart';
import '../../domain/entities/auth_session.dart';
import 'apple_sign_in_state.dart';

/// Native Sign in with Apple (iOS only) : the session is established
/// synchronously, so this controller navigates itself on success — same
/// pattern as [GoogleSignInController]/[LoginController].
class AppleSignInController extends Notifier<AppleSignInState> {
  @override
  AppleSignInState build() => const AppleSignInState();

  Future<void> signIn() async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      clearFormError: true,
      succeeded: false,
    );

    final result = await ref.read(signInWithAppleProvider)();
    switch (result) {
      case Ok<AuthSession>(:final value):
        state = state.copyWith(
          isLoading: false,
          succeeded: true,
          email: value.email,
        );
      case Err<AuthSession>(:final failure):
        state = state.copyWith(isLoading: false, formError: failure.message);
    }
  }
}

final appleSignInControllerProvider =
    NotifierProvider.autoDispose<AppleSignInController, AppleSignInState>(
      AppleSignInController.new,
    );
