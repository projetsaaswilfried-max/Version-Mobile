import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../interests/di/interests_providers.dart';
import '../../domain/entities/more_info_details.dart';
import '../account/account_save_feedback.dart';
import '../account/widgets/account_editor_scaffold.dart';
import '../account/widgets/account_list_widgets.dart';
import 'more_info_controller.dart';

class MoreInfoPage extends ConsumerStatefulWidget {
  const MoreInfoPage({super.key});

  @override
  ConsumerState<MoreInfoPage> createState() => _MoreInfoPageState();
}

class _MoreInfoPageState extends ConsumerState<MoreInfoPage> {
  late final TextEditingController _family;
  late final TextEditingController _children;
  late final TextEditingController _horizon;
  late final TextEditingController _likes;
  late final TextEditingController _dislikes;
  var _seeded = false;

  @override
  void initState() {
    super.initState();
    _family = TextEditingController();
    _children = TextEditingController();
    _horizon = TextEditingController();
    _likes = TextEditingController();
    _dislikes = TextEditingController();
  }

  @override
  void dispose() {
    _family.dispose();
    _children.dispose();
    _horizon.dispose();
    _likes.dispose();
    _dislikes.dispose();
    super.dispose();
  }

  void _seed() {
    final details = ref.read(moreInfoControllerProvider).details;
    if (details == null || _seeded) return;
    _seeded = true;
    _family.text = details.familyVision;
    _children.text = details.childrenWanted;
    _horizon.text = details.marriageHorizon;
    _likes.text = details.likes;
    _dislikes.text = details.dislikes;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(moreInfoControllerProvider);
    final notifier = ref.read(moreInfoControllerProvider.notifier);
    final interestsAsync = ref.watch(interestsListProvider);
    _seed();
    final details = state.details;

    return AccountEditorScaffold(
      title: 'Plus d\'infos',
      isLoading: state.isInitialLoading,
      errorMessage: state.details == null ? state.errorMessage : null,
      onRetry: notifier.loadInitial,
      isSaving: state.isSaving,
      saveError: state.saveError,
      onSave: () async {
        final ok = await notifier.save();
        if (!ok || !context.mounted) return;
        await popAfterAccountSave(context, ref);
      },
      child: details == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                if (details.qualitiesAvailable)
                  TagField(
                    label: 'Qualités',
                    hint: 'hors matching',
                    tags: details.qualities,
                    max: MoreInfoDetails.maxQualities,
                    onChanged: (tags) =>
                        notifier.update((d) => d.copyWith(qualities: tags)),
                  ),
                if (details.passionsAvailable) ...[
                  const SizedBox(height: AppSpacing.lg),
                  switch (interestsAsync) {
                    AsyncData(:final value) => AppMultiSelectChips(
                      label: 'Passions',
                      hint: 'hors matching',
                      items: [
                        for (final interest in value)
                          AppOptionItem(
                            id: interest.name,
                            label: interest.name,
                          ),
                      ],
                      selected: details.passions,
                      max: MoreInfoDetails.maxPassions,
                      onChanged: (tags) =>
                          notifier.update((d) => d.copyWith(passions: tags)),
                    ),
                    AsyncError() => Text(
                      'Impossible de charger les passions.',
                      style: context.typography.bodySmall.copyWith(
                        color: context.colors.error,
                      ),
                    ),
                    _ => const Center(child: CircularProgressIndicator()),
                  },
                ],
                if (details.valuesAvailable) ...[
                  const SizedBox(height: AppSpacing.lg),
                  TagField(
                    label: 'Valeurs',
                    hint: '12 max',
                    tags: details.values,
                    max: MoreInfoDetails.maxValues,
                    onChanged: (tags) =>
                        notifier.update((d) => d.copyWith(values: tags)),
                  ),
                ],
                if (details.familyVisionAvailable) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: 'Vision familiale',
                    controller: _family,
                    maxLines: 4,
                    maxLength: 1000,
                    onChanged: (v) =>
                        notifier.update((d) => d.copyWith(familyVision: v)),
                  ),
                ],
                if (details.childrenWantedAvailable) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Enfants souhaités',
                    controller: _children,
                    onChanged: (v) =>
                        notifier.update((d) => d.copyWith(childrenWanted: v)),
                  ),
                ],
                if (details.marriageHorizonAvailable) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Horizon de mariage',
                    controller: _horizon,
                    onChanged: (v) =>
                        notifier.update((d) => d.copyWith(marriageHorizon: v)),
                  ),
                ],
                if (details.likesAvailable) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'J\'aime',
                    controller: _likes,
                    onChanged: (v) =>
                        notifier.update((d) => d.copyWith(likes: v)),
                  ),
                ],
                if (details.dislikesAvailable) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Je n\'aime pas',
                    controller: _dislikes,
                    onChanged: (v) =>
                        notifier.update((d) => d.copyWith(dislikes: v)),
                  ),
                ],
              ],
            ),
    );
  }
}
