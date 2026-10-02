import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_toast.dart';
import '../../../profile/presentation/navigation/navigate_after_auth.dart';
import '../google/google_sign_in_controller.dart';
import 'google_sign_in_button.dart';

/// Shared native Google Sign-In button (no browser, no deep link) — used
/// from Login/Registration/Welcome. Navigates itself on success, same
/// pattern as [LoginPage] with [LoginController].
class GoogleAuthButton extends ConsumerWidget {
  const GoogleAuthButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(googleSignInControllerProvider, (previous, next) async {
      if (next.succeeded && previous?.succeeded != true) {
        await navigateAfterAuth(ref, context, email: next.email);
        return;
      }
      if (next.formError != null &&
          next.formError != previous?.formError &&
          !next.isLoading) {
        // TODO(debug): message brut temporaire pour diagnostiquer l'échec
        // Google Sign-In en prod Android - revenir à
        // userFacingMessageFromRaw(next.formError) une fois la vraie cause
        // identifiée.
        AppToast.show(context, next.formError!);
      }
    });

    final state = ref.watch(googleSignInControllerProvider);
    return GoogleSignInButton(
      onPressed: state.isLoading
          ? null
          : () => ref.read(googleSignInControllerProvider.notifier).signIn(),
    );
  }
}
