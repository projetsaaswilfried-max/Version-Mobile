import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/widgets.dart';
import '../onboarding_flow_controller.dart';
import '../onboarding_option_mapping.dart';

class FaithWhyStep extends ConsumerStatefulWidget {
  const FaithWhyStep({super.key});

  @override
  ConsumerState<FaithWhyStep> createState() => _FaithWhyStepState();
}

class _FaithWhyStepState extends ConsumerState<FaithWhyStep> {
  late final TextEditingController _whyMarriageController;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingFlowProvider).draft;
    _whyMarriageController = TextEditingController(text: draft.whyMarriage);
  }

  @override
  void dispose() {
    _whyMarriageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingFlowProvider);
    final controller = ref.read(onboardingFlowProvider.notifier);
    final draft = state.draft;
    final errors = state.fieldErrors;
    final typography = context.typography;
    final confession = draft.faithConfession.trim();

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
          AppSelectField(
            label: 'Confession chrétienne',
            sheetTitle: 'Confession chrétienne',
            hint: 'Choisir',
            options: onboardingFaithConfessions,
            value: confession.isEmpty ? null : confession,
            errorText: errors['faithConfession'],
            onChanged: (v) =>
                controller.updateDraft((d) => d.copyWith(faithConfession: v)),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Situation matrimoniale', style: typography.label),
          const SizedBox(height: AppSpacing.sm),
          AppOptionChips(
            items: onboardingMaritalItems(),
            selectedId: draft.maritalStatus == null
                ? null
                : onboardingMaritalId(draft.maritalStatus!),
            errorText: errors['maritalStatus'],
            onSelected: (id) {
              final status = onboardingMaritalFromId(id);
              if (status == null) return;
              controller.updateDraft((d) => d.copyWith(maritalStatus: status));
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: 'Pourquoi cherches-tu le mariage ?',
            maxLines: 4,
            minLines: 3,
            controller: _whyMarriageController,
            errorText: errors['whyMarriage'],
            onChanged: (v) =>
                controller.updateDraft((d) => d.copyWith(whyMarriage: v)),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
