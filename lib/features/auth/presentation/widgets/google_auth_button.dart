import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/user_facing_message.dart';
import '../../../../core/widgets/app_toast.dart';
import '../google/google_sign_in_controller.dart';
import 'google_sign_in_button.dart';

/// Shared Google OAuth button. Navigation on success happens elsewhere —
/// see [GoogleSignInController] — this only surfaces the loading/error
/// state of launching the OAuth flow.
class GoogleAuthButton extends ConsumerWidget {
  const GoogleAuthButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(googleSignInControllerProvider, (previous, next) {
      if (next.formError != null &&
          next.formError != previous?.formError &&
          !next.isLoading) {
        AppToast.show(context, userFacingMessageFromRaw(next.formError));
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
