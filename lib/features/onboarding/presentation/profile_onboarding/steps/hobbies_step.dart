import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../profile/domain/entities/more_info_details.dart';
import '../../../../profile/presentation/account/widgets/account_list_widgets.dart';
import '../onboarding_flow_controller.dart';

/// Étape obligatoire (D34) : au moins un centre d'intérêt est requis pour
/// continuer, sans quoi le profil resterait incomplet et n'apparaîtrait pas
/// dans Découvrir (`discover_profile_model.dart:_isComplete`).
class HobbiesStep extends ConsumerStatefulWidget {
  const HobbiesStep({super.key});

  @override
  ConsumerState<HobbiesStep> createState() => _HobbiesStepState();
}

class _HobbiesStepState extends ConsumerState<HobbiesStep> {
  late final TextEditingController _bioController;
  late final TextEditingController _heightController;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingFlowProvider).draft;
    _bioController = TextEditingController(text: draft.bio);
    _heightController = TextEditingController(
      text: draft.heightCm?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingFlowProvider);
    final draft = state.draft;
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
            errorText: state.fieldErrors['hobbies'],
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: 'Présente-toi',
            hint: 'Quelques lignes sur toi…',
            controller: _bioController,
            maxLines: 5,
            minLines: 4,
            maxLength: 600,
            keyboardType: TextInputType.multiline,
            onChanged: (value) =>
                controller.updateDraft((d) => d.copyWith(bio: value)),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Taille (cm)',
            hint: 'ex. 175',
            controller: _heightController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              final parsed = int.tryParse(value.trim());
              controller.updateDraft(
                (d) => parsed == null
                    ? d.copyWith(clearHeight: true)
                    : d.copyWith(heightCm: parsed),
              );
            },
          ),
        ],
      ),
    );
  }
}
