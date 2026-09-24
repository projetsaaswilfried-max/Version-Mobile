import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/user_facing_message.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../profile/presentation/navigation/navigate_after_auth.dart';
import '../apple/apple_sign_in_controller.dart';
import 'apple_sign_in_button.dart';

/// Shared native Sign in with Apple button - iOS uniquement (exigence App
/// Store 4.8 dès qu'un login social tiers comme Google est proposé ;
/// aucune obligation ni intérêt sur Android). Navigue lui-même sur succès,
/// même schéma que [GoogleAuthButton].
class AppleAuthButton extends ConsumerWidget {
  const AppleAuthButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Platform.isIOS) return const SizedBox.shrink();

    ref.listen(appleSignInControllerProvider, (previous, next) async {
      if (next.succeeded && previous?.succeeded != true) {
        await navigateAfterAuth(ref, context, email: next.email);
        return;
      }
      if (next.formError != null &&
          next.formError != previous?.formError &&
          !next.isLoading) {
        AppToast.show(context, userFacingMessageFromRaw(next.formError));
      }
    });

    final state = ref.watch(appleSignInControllerProvider);
    return AppleSignInButton(
      onPressed: state.isLoading
          ? null
          : () => ref.read(appleSignInControllerProvider.notifier).signIn(),
    );
  }
}
