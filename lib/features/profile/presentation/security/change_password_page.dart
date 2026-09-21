import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/di/auth_providers.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../account/widgets/account_editor_scaffold.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  var _saving = false;
  String? _error;
  var _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref.read(updatePasswordProvider)(
      password: _password.text,
      passwordConfirm: _confirm.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok<AuthSession>():
        AppToast.show(context, 'Mot de passe mis à jour.', isError: false);
        Navigator.of(context).pop();
      case Err<AuthSession>(:final failure):
        setState(() => _error = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccountEditorScaffold(
      title: 'Changer le mot de passe',
      isLoading: false,
      errorMessage: null,
      onRetry: () {},
      isSaving: _saving,
      saveError: _error,
      onSave: _save,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppTextField(
            label: 'Nouveau mot de passe',
            controller: _password,
            obscureText: _obscure,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Confirmer',
            controller: _confirm,
            obscureText: _obscure,
          ),
        ],
      ),
    );
  }
}
