import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/welcome/welcome_page.dart';
import '../../di/profile_providers.dart';
import '../account/widgets/account_editor_scaffold.dart';

class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  var _saving = false;
  String? _error;

  Future<void> _confirm() async {
    final ok = await AppConfirmDialog.show(
      context,
      title: 'Supprimer mon compte',
      message:
          'Cette action est irréversible. Tes données de profil seront perdues.',
      confirmLabel: 'Supprimer',
      icon: Icons.warning_amber_rounded,
    );
    if (ok != true || !mounted) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref
        .read(profileAccountRepositoryProvider)
        .deleteAccount();
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok<void>():
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const WelcomePage()),
          (route) => false,
        );
      case Err<void>(:final failure):
        setState(() => _error = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccountEditorScaffold(
      title: 'Supprimer mon compte',
      isLoading: false,
      errorMessage: null,
      onRetry: () {},
      isSaving: _saving,
      saveError: _error,
      saveLabel: 'Supprimer définitivement',
      onSave: _confirm,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'La suppression est définitive. Tu pourras te réinscrire plus tard avec un nouveau compte.',
          style: context.typography.bodyMedium,
        ),
      ),
    );
  }
}
