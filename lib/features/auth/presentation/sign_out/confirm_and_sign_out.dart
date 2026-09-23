import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../push_notifications/di/push_notifications_providers.dart';
import '../../di/auth_providers.dart';
import '../welcome/welcome_page.dart';

Future<void> confirmAndSignOut(BuildContext context, WidgetRef ref) async {
  final confirmed = await AppConfirmDialog.show(
    context,
    title: 'Se déconnecter ?',
    message: 'Tu pourras te reconnecter à tout moment.',
    confirmLabel: 'Déconnexion',
  );
  if (confirmed != true || !context.mounted) return;

  // Avant d'invalider la session : la policy RLS delete_own de
  // device_tokens a besoin d'un auth.uid() valide.
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await ref.read(deviceTokensRepositoryProvider).deleteToken(token);
    }
  } catch (_) {
    // Ne doit jamais bloquer la déconnexion.
  }

  final result = await ref.read(signOutProvider)();
  if (!context.mounted) return;

  switch (result) {
    case Ok<void>():
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const WelcomePage()),
        (_) => false,
      );
    case Err<void>(:final failure):
      AppToast.show(context, userFacingMessage(failure));
  }
}
