import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_toast.dart';
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
