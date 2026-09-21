import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/error/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../di/profile_providers.dart';
import '../account/widgets/account_editor_scaffold.dart';

class ExportDataPage extends ConsumerStatefulWidget {
  const ExportDataPage({super.key});

  @override
  ConsumerState<ExportDataPage> createState() => _ExportDataPageState();
}

class _ExportDataPageState extends ConsumerState<ExportDataPage> {
  var _loading = false;
  String? _error;

  Future<void> _export() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ref
        .read(profileAccountRepositoryProvider)
        .exportJson();
    if (!mounted) return;
    setState(() => _loading = false);
    switch (result) {
      case Ok<String>(:final value):
        await SharePlus.instance.share(ShareParams(text: value));
      case Err<String>(:final failure):
        setState(() => _error = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccountEditorScaffold(
      title: 'Export des données',
      isLoading: false,
      errorMessage: null,
      onRetry: () {},
      isSaving: _loading,
      saveError: _error,
      saveLabel: 'Exporter en JSON',
      onSave: _export,
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'Le fichier JSON est généré sur cet appareil. Il n\'est jamais envoyé par email.',
        ),
      ),
    );
  }
}
