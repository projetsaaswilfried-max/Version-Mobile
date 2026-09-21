import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/church_denominations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../account/account_save_feedback.dart';
import '../account/widgets/account_editor_scaffold.dart';
import 'faith_controller.dart';

class FaithPage extends ConsumerStatefulWidget {
  const FaithPage({super.key});

  @override
  ConsumerState<FaithPage> createState() => _FaithPageState();
}

class _FaithPageState extends ConsumerState<FaithPage> {
  late final TextEditingController _why;
  late final TextEditingController _engagement;
  late final TextEditingController _ministry;
  late final TextEditingController _years;
  late final TextEditingController _verse;
  late final TextEditingController _testimony;
  late final TextEditingController _godWork;
  var _seeded = false;

  @override
  void initState() {
    super.initState();
    _why = TextEditingController();
    _engagement = TextEditingController();
    _ministry = TextEditingController();
    _years = TextEditingController();
    _verse = TextEditingController();
    _testimony = TextEditingController();
    _godWork = TextEditingController();
  }

  @override
  void dispose() {
    _why.dispose();
    _engagement.dispose();
    _ministry.dispose();
    _years.dispose();
    _verse.dispose();
    _testimony.dispose();
    _godWork.dispose();
    super.dispose();
  }

  void _seed() {
    final details = ref.read(faithControllerProvider).details;
    if (details == null || _seeded) return;
    _seeded = true;
    _why.text = details.whyMarriage;
    _engagement.text = details.spiritualEngagement;
    _ministry.text = details.ministry;
    _years.text = details.yearsConverted;
    _verse.text = details.verse;
    _testimony.text = details.testimony;
    _godWork.text = details.godWork;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(faithControllerProvider);
    final notifier = ref.read(faithControllerProvider.notifier);
    _seed();
    final details = state.details;

    return AccountEditorScaffold(
      title: 'Ma Foi',
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
                if (details.denominationAvailable)
                  AppSelectField(
                    label: 'Confession',
                    sheetTitle: 'Confession chrétienne',
                    options: churchDenominations,
                    value: details.denomination.trim().isEmpty
                        ? null
                        : details.denomination,
                    onChanged: (v) =>
                        notifier.update((d) => d.copyWith(denomination: v)),
                  ),
                if (details.whyMarriageAvailable) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Pourquoi le mariage',
                    controller: _why,
                    maxLines: 4,
                    maxLength: 1000,
                    onChanged: (v) =>
                        notifier.update((d) => d.copyWith(whyMarriage: v)),
                  ),
                ],
                if (details.spiritualEngagementAvailable) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Engagement spirituel',
                    controller: _engagement,
                    onChanged: (v) => notifier.update(
                      (d) => d.copyWith(spiritualEngagement: v),
                    ),
                  ),
                ],
                if (details.ministryAvailable) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Ministère',
                    controller: _ministry,
                    onChanged: (v) =>
                        notifier.update((d) => d.copyWith(ministry: v)),
                  ),
                ],
                if (details.yearsConvertedAvailable) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Années de cheminement',
                    controller: _years,
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        notifier.update((d) => d.copyWith(yearsConverted: v)),
                  ),
                ],
                if (details.verseAvailable) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Verset préféré',
                    controller: _verse,
                    maxLines: 3,
                    maxLength: 200,
                    onChanged: (v) =>
                        notifier.update((d) => d.copyWith(verse: v)),
                  ),
                ],
                if (details.testimonyAvailable) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Témoignage',
                    controller: _testimony,
                    maxLines: 5,
                    maxLength: 600,
                    onChanged: (v) =>
                        notifier.update((d) => d.copyWith(testimony: v)),
                  ),
                ],
                if (details.godWorkAvailable) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Ce que Dieu fait dans ma vie',
                    controller: _godWork,
                    maxLines: 5,
                    maxLength: 600,
                    onChanged: (v) =>
                        notifier.update((d) => d.copyWith(godWork: v)),
                  ),
                ],
                if (details.baptizedAvailable)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Baptisé(e)',
                      style: context.typography.bodyLarge,
                    ),
                    value: details.baptized,
                    onChanged: (v) =>
                        notifier.update((d) => d.copyWith(baptized: v)),
                  ),
              ],
            ),
    );
  }
}
