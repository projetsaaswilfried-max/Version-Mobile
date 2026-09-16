import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../google/google_sign_in_controller.dart';
import '../session_stub/session_stub_page.dart';
import 'google_sign_in_button.dart';

/// Shared Google OAuth button + navigation to session stub on success.
class GoogleAuthButton extends ConsumerWidget {
  const GoogleAuthButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(googleSignInControllerProvider, (previous, next) {
      if (next.formError != null &&
          next.formError != previous?.formError &&
          !next.isLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.formError!)));
      }
      if (!next.succeeded || previous?.succeeded == true) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => SessionStubPage(email: next.email),
        ),
        (route) => false,
      );
    });

    final state = ref.watch(googleSignInControllerProvider);
    return GoogleSignInButton(
      onPressed: state.isLoading
          ? null
          : () => ref.read(googleSignInControllerProvider.notifier).signIn(),
    );
  }
}
