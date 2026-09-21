import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_toast.dart';
import '../../di/profile_providers.dart';
import '../hub/profile_hub_controller.dart';

Future<void> popAfterAccountSave(
  BuildContext context,
  WidgetRef ref, {
  String message = 'Enregistré.',
}) async {
  ref.invalidate(profileFieldsProvider);
  await ref.read(profileHubControllerProvider.notifier).loadInitial();
  if (!context.mounted) return;
  AppToast.show(context, message, isError: false);
  Navigator.of(context).pop();
}
