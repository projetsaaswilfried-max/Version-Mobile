import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../discover/presentation/widgets/discover_premium_sheet.dart';
import '../account/account_people_controllers.dart';
import '../account/open_account_person_sheet.dart';
import '../account/widgets/account_editor_scaffold.dart';
import '../account/widgets/account_list_widgets.dart';

class InterestedPage extends ConsumerWidget {
  const InterestedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(interestedControllerProvider);
    final notifier = ref.read(interestedControllerProvider.notifier);
    final count = state.count ?? state.people.length;

    return AccountEditorScaffold(
      title: 'Qui s\'intéresse à moi',
      isLoading: state.isInitialLoading,
      errorMessage: state.errorMessage,
      onRetry: notifier.loadInitial,
      isSaving: false,
      showSave: false,
      onSave: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              '$count personne${count > 1 ? 's' : ''} s\'intéresse${count > 1 ? 'nt' : ''} à toi',
              style: context.typography.bodyLarge,
            ),
          ),
          if (!state.revealIdentities)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextButton(
                onPressed: () => DiscoverPremiumSheet.show(context),
                child: const Text('Voir les identités avec Premium'),
              ),
            ),
          Expanded(
            child: count == 0
                ? const AccountEmptyState(
                    message: 'Personne pour le moment',
                    detail: 'Les likes reçus apparaîtront ici.',
                  )
                : AppProfileGrid(
                    itemCount: state.people.length,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    itemBuilder: (context, index) {
                      final person = state.people[index];
                      return AppProfileGridCard(
                        title: person.displayName,
                        photoUrl: person.photoUrl,
                        subtitle: person.city,
                        onTap: () => openAccountPersonSheet(
                          context: context,
                          ref: ref,
                          profileId: person.id,
                          identityRevealed: person.identityRevealed,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
