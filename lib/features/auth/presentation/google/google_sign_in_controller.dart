import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../di/auth_providers.dart';
import '../../domain/entities/auth_session.dart';
import 'google_sign_in_state.dart';

/// Native Google Sign-In (no browser, no deep link) : the session is
/// established synchronously, so this controller navigates itself on
/// success — same pattern as [LoginController].
class GoogleSignInController extends Notifier<GoogleSignInState> {
  @override
  GoogleSignInState build() => const GoogleSignInState();

  Future<void> signIn() async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      clearFormError: true,
      succeeded: false,
    );

    final result = await ref.read(signInWithGoogleProvider)();
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

final googleSignInControllerProvider =
    NotifierProvider.autoDispose<GoogleSignInController, GoogleSignInState>(
      GoogleSignInController.new,
    );
