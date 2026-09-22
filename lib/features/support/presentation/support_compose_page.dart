import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../di/support_providers.dart';
import '../domain/entities/support_ticket.dart';

class SupportComposePage extends ConsumerStatefulWidget {
  const SupportComposePage({super.key});

  @override
  ConsumerState<SupportComposePage> createState() => _SupportComposePageState();
}

class _SupportComposePageState extends ConsumerState<SupportComposePage> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  var _saving = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_subject.text.trim().isEmpty || _message.text.trim().isEmpty) {
      AppToast.show(context, 'Objet et message sont requis.');
      return;
    }
    setState(() => _saving = true);
    final result = await ref
        .read(supportRepositoryProvider)
        .openTicket(subject: _subject.text, message: _message.text);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok<SupportTicket>():
        Navigator.of(context).pop();
      case Err<SupportTicket>(:final failure):
        AppToast.show(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau dossier')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppTextField(hint: 'Objet', controller: _subject),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            hint: 'Message',
            controller: _message,
            minLines: 4,
            maxLines: 8,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: 'Envoyer', isLoading: _saving, onPressed: _submit),
        ],
      ),
    );
  }
}
