import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../account/account_people_controllers.dart';
import '../account/widgets/account_editor_scaffold.dart';
import '../account/widgets/account_list_widgets.dart';

class BlockedAccountsPage extends ConsumerWidget {
  const BlockedAccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(blockedControllerProvider);
    final notifier = ref.read(blockedControllerProvider.notifier);

    return AccountEditorScaffold(
      title: 'Comptes bloqués',
      isLoading: state.isInitialLoading,
      errorMessage: state.errorMessage,
      onRetry: notifier.loadInitial,
      isSaving: false,
      showSave: false,
      onSave: null,
      child: state.people.isEmpty
          ? const AccountEmptyState(
              message: 'Aucun compte bloqué',
              detail: 'Les comptes que tu bloques apparaîtront ici.',
            )
          : ListView.builder(
              itemCount: state.people.length,
              itemBuilder: (context, index) {
                final person = state.people[index];
                return AccountPersonTile(
                  person: person,
                  trailing: TextButton(
                    onPressed: () => notifier.unblock(person.id),
                    child: const Text('Débloquer'),
                  ),
                );
              },
            ),
    );
  }
}
