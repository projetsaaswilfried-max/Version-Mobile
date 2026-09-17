import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../di/auth_providers.dart';
import 'google_sign_in_state.dart';

/// Launches Google OAuth and tracks the loading/error state of that launch
/// only. It does NOT navigate on success and does NOT listen to
/// [AuthRepository.authStateChanges] — `signInWithGoogle()` only opens the
/// external browser, it never itself yields a session (see
/// `SupabaseAuthDataSource.signInWithGoogle`). The session is established
/// later, exclusively via the OAuth redirect deep link, handled by
/// `AuthDeepLinkListener` (mounted globally in main.dart) — that's the
/// single source of truth for post-login navigation.
///
/// This controller used to also subscribe to `authStateChanges` and
/// navigate itself on the first non-null session, racing the deep link
/// listener for the exact same event: both would fire `pushAndRemoveUntil`
/// for the same login, on different navigators, in unpredictable order.
class GoogleSignInController extends Notifier<GoogleSignInState> {
  Timer? _timeout;

  @override
  GoogleSignInState build() {
    ref.onDispose(() => _timeout?.cancel());
    return const GoogleSignInState();
  }

  Future<void> signIn() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearFormError: true);

    final result = await ref.read(signInWithGoogleProvider)();
    switch (result) {
      case Err<void>(:final failure):
        state = state.copyWith(isLoading: false, formError: failure.message);
        return;
      case Ok<void>():
        break;
    }

    // The browser is open; wait for the deep link to come back and reset
    // the button if the member bails out or it never returns.
    _timeout?.cancel();
    _timeout = Timer(const Duration(minutes: 2), () {
      if (state.isLoading) {
        state = state.copyWith(
          isLoading: false,
          formError: 'Connexion Google annulée ou expirée.',
        );
      }
    });
  }
}

final googleSignInControllerProvider =
    NotifierProvider.autoDispose<GoogleSignInController, GoogleSignInState>(
      GoogleSignInController.new,
    );
