import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../profile/domain/entities/more_info_details.dart';
import '../../../../profile/presentation/account/widgets/account_list_widgets.dart';
import '../onboarding_flow_controller.dart';

/// Étape optionnelle (skippable, comme la photo) : sans centres d'intérêt,
/// le profil reste incomplet et n'apparaît pas dans Découvrir
/// (`discover_profile_model.dart:_isComplete`).
class HobbiesStep extends ConsumerWidget {
  const HobbiesStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingFlowProvider).draft;
    final controller = ref.read(onboardingFlowProvider.notifier);
    final typography = context.typography;
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Qu\'est-ce qui te passionne ?',
            style: typography.bodyMedium.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          TagField(
            label: 'Centres d\'intérêt',
            hint: 'ex. randonnée, cuisine, lecture…',
            tags: draft.hobbies,
            max: MoreInfoDetails.maxPassions,
            onChanged: (tags) =>
                controller.updateDraft((d) => d.copyWith(hobbies: tags)),
          ),
        ],
      ),
    );
  }
}
