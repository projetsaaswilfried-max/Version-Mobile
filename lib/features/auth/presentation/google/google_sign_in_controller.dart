import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../di/auth_providers.dart';
import '../../domain/entities/auth_session.dart';
import 'google_sign_in_state.dart';

class GoogleSignInController extends Notifier<GoogleSignInState> {
  StreamSubscription<AuthSession?>? _sub;
  Timer? _timeout;

  @override
  GoogleSignInState build() {
    ref.onDispose(() {
      _sub?.cancel();
      _timeout?.cancel();
    });
    return const GoogleSignInState();
  }

  Future<void> signIn() async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      clearFormError: true,
      succeeded: false,
    );

    final result = await ref.read(signInWithGoogleProvider)();
    switch (result) {
      case Err<void>(:final failure):
        state = state.copyWith(isLoading: false, formError: failure.message);
        return;
      case Ok<void>():
        break;
    }

    final existing = ref.read(authRepositoryProvider).currentSession;
    if (existing != null) {
      state = state.copyWith(
        isLoading: false,
        succeeded: true,
        email: existing.email,
      );
      return;
    }

    await _sub?.cancel();
    _timeout?.cancel();
    final repo = ref.read(authRepositoryProvider);
    _sub = repo.authStateChanges.listen((session) {
      if (session == null) return;
      _timeout?.cancel();
      state = state.copyWith(
        isLoading: false,
        succeeded: true,
        email: session.email,
      );
      _sub?.cancel();
    });

    _timeout = Timer(const Duration(minutes: 2), () {
      if (state.isLoading && !state.succeeded) {
        state = state.copyWith(
          isLoading: false,
          formError: 'Connexion Google annulée ou expirée.',
        );
        _sub?.cancel();
      }
    });
  }
}

final googleSignInControllerProvider =
    NotifierProvider.autoDispose<GoogleSignInController, GoogleSignInState>(
      GoogleSignInController.new,
    );
