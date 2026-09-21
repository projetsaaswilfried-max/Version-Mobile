import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../account/account_people_controllers.dart';
import '../account/open_account_person_sheet.dart';
import '../account/widgets/account_editor_scaffold.dart';
import '../account/widgets/account_list_widgets.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _confirmRemove(
    BuildContext context, {
    required String name,
    required VoidCallback onConfirm,
  }) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Retirer des favoris ?',
      message: '$name ne sera plus dans tes favoris.',
      confirmLabel: 'Retirer',
      icon: Icons.bookmark_remove_outlined,
    );
    if (confirmed == true) onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(favoritesControllerProvider);
    final notifier = ref.read(favoritesControllerProvider.notifier);
    final visible = state.visible;

    return AccountEditorScaffold(
      title: 'Mes Favoris',
      isLoading: state.isInitialLoading,
      errorMessage: state.errorMessage,
      onRetry: notifier.loadInitial,
      isSaving: false,
      showSave: false,
      onSave: null,
      child: Column(
        children: [
          AccountSearchField(controller: _search, onChanged: notifier.search),
          Expanded(
            child: visible.isEmpty
                ? const AccountEmptyState(
                    message: 'Aucun favori',
                    detail: 'Ajoute des profils depuis Découvrir.',
                  )
                : AppProfileGrid(
                    itemCount: visible.length,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    itemBuilder: (context, index) {
                      final person = visible[index];
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
                        trailing: _RemoveFavoriteButton(
                          onPressed: () => _confirmRemove(
                            context,
                            name: person.displayName,
                            onConfirm: () => notifier.remove(person.id),
                          ),
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

class _RemoveFavoriteButton extends StatelessWidget {
  const _RemoveFavoriteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Retirer des favoris',
      child: Material(
        color: Colors.black.withValues(alpha: 0.35),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const SizedBox(
            width: 32,
            height: 32,
            child: Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}
