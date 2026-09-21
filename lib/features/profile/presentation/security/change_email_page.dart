import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/domain/validation/auth_validators.dart';
import '../../di/profile_providers.dart';
import '../account/widgets/account_editor_scaffold.dart';

class ChangeEmailPage extends ConsumerStatefulWidget {
  const ChangeEmailPage({super.key});

  @override
  ConsumerState<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends ConsumerState<ChangeEmailPage> {
  final _email = TextEditingController();
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final message = AuthValidators.email(_email.text);
    if (message != null) {
      setState(() => _error = message);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref
        .read(profileAccountRepositoryProvider)
        .changeEmail(_email.text.trim());
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok<void>():
        AppToast.show(
          context,
          'Vérifie ta boîte mail pour confirmer.',
          isError: false,
        );
        Navigator.of(context).pop();
      case Err<void>(:final failure):
        setState(() => _error = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccountEditorScaffold(
      title: 'Changer l\'email',
      isLoading: false,
      errorMessage: null,
      onRetry: () {},
      isSaving: _saving,
      saveError: _error,
      saveLabel: 'Enregistrer',
      onSave: _save,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: AppTextField(
          label: 'Nouvel email',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
      ),
    );
  }
}
