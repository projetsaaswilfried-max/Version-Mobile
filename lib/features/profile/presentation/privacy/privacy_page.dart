import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../account/account_save_feedback.dart';
import '../account/widgets/account_editor_scaffold.dart';
import '../account/widgets/account_list_widgets.dart';
import 'privacy_controller.dart';

class PrivacyPage extends ConsumerWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(privacyControllerProvider);
    final notifier = ref.read(privacyControllerProvider.notifier);
    final settings = state.settings;

    return AccountEditorScaffold(
      title: 'Confidentialité',
      isLoading: state.isInitialLoading,
      errorMessage: state.settings == null ? state.errorMessage : null,
      onRetry: notifier.loadInitial,
      isSaving: state.isSaving,
      saveError: state.saveError,
      showSave: settings != null && !settings.isEmpty,
      onSave: () async {
        final ok = await notifier.save();
        if (!ok || !context.mounted) return;
        await popAfterAccountSave(context, ref);
      },
      child: settings == null
          ? const SizedBox.shrink()
          : settings.isEmpty
          ? const AccountEmptyState(
              message: 'Aucune option disponible',
              detail:
                  'Les réglages de confidentialité n\'ont pas pu être chargés.',
            )
          : ListView(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              children: [
                AppSettingsGroup(
                  children: [
                    for (final item in settings.switches)
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        title: Text(
                          item.label,
                          style: context.typography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        value: item.value,
                        onChanged: (value) => notifier.toggle(item.id, value),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}
