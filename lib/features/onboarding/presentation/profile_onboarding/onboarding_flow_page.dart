import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../home/presentation/home_shell_page.dart';
import 'onboarding_draft.dart';
import 'onboarding_flow_controller.dart';
import 'onboarding_flow_state.dart';
import 'steps/essentials_step.dart';
import 'steps/faith_why_step.dart';
import 'steps/hobbies_step.dart';
import 'steps/profile_photo_step.dart';
import 'steps/recap_step.dart';
import 'steps/selfie_verification_step.dart';

/// Onboarding profil : 3 étapes métier + récap, chrome sombre façon Behance.
class OnboardingFlowPage extends ConsumerStatefulWidget {
  const OnboardingFlowPage({super.key});

  @override
  ConsumerState<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends ConsumerState<OnboardingFlowPage> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: ref.read(onboardingFlowProvider).currentStep,
    );
  }

  static const _titles = [
    'Parle-nous de toi',
    'Ta foi',
    'Tes passions',
    'Ta photo',
    'Vérifie ton identité',
    'Récapitulatif',
  ];

  static const _subtitles = [
    'Genre, âge et pays : verrouillés après validation.',
    'Confession, situation et pourquoi tu cherches le mariage.',
    'Tes centres d\'intérêt, ta présentation et ta taille.',
    'Ajoute ta photo de profil.',
    'Un selfie pour confirmer que c\'est bien toi.',
    'Vérifie avant de valider ton profil.',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onCompleted(OnboardingFlowState state) {
    final message = state.skippedPhoto
        ? 'Profil enregistré sans photo.'
        : 'Profil enregistré.';
    AppToast.show(context, message, isError: false);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeShellPage()),
      (route) => false,
    );
  }

  Future<void> _confirmSkipPhoto(OnboardingFlowController controller) async {
    const warning =
        'Sans photo, ton profil ne sera pas vérifié ni visible. '
        'Tu pourras en ajouter plus tard.';
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Continuer sans photo ?',
      message: warning,
      confirmLabel: 'Continuer sans photo',
      icon: Icons.photo_outlined,
    );
    if (confirmed == true && mounted) {
      await controller.skipPhoto();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(onboardingFlowProvider, (previous, next) {
      if (next.currentStep != previous?.currentStep) {
        _pageController.animateToPage(
          next.currentStep,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
      if (next.completedLocally && previous?.completedLocally != true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _onCompleted(next);
        });
      }
      if (next.submitError != null &&
          next.submitError != previous?.submitError) {
        AppToast.show(context, userFacingMessageFromRaw(next.submitError));
      }
    });

    final state = ref.watch(onboardingFlowProvider);
    final controller = ref.read(onboardingFlowProvider.notifier);
    final colors = context.colors;
    final typography = context.typography;
    final busy = state.isSubmitting;
    final step = state.currentStep.clamp(0, _titles.length - 1);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: colors.scrim,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: busy
                              ? null
                              : () {
                                  if (state.currentStep == 0) {
                                    Navigator.of(context).maybePop();
                                  } else {
                                    controller.back();
                                  }
                                },
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: colors.onScrim,
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              for (
                                var i = 0;
                                i < OnboardingFlowState.stepCount;
                                i++
                              )
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xxs,
                                    ),
                                    height: AppSpacing.xs,
                                    decoration: BoxDecoration(
                                      color: i <= state.currentStep
                                          ? colors.primary
                                          : colors.onScrim.withValues(
                                              alpha: 0.22,
                                            ),
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.xxs,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _titles[step],
                            style: typography.headline.copyWith(
                              color: colors.onScrim,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _subtitles[step],
                            style: typography.bodyMedium.copyWith(
                              color: colors.onScrim.withValues(alpha: 0.78),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xl),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xl),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: const [
                            EssentialsStep(),
                            FaithWhyStep(),
                            HobbiesStep(),
                            ProfilePhotoStep(),
                            SelfieVerificationStep(),
                            RecapStep(),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          AppSpacing.sm,
                          AppSpacing.xl,
                          AppSpacing.xl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (state.isRecapStep) ...[
                              AppButton(
                                label: 'Terminer',
                                isLoading: busy,
                                onPressed:
                                    busy ||
                                        state.draft.profilePhotoPath == null ||
                                        state.draft.selfiePath == null
                                    ? null
                                    : controller.submit,
                              ),
                            ] else ...[
                              AppButton(
                                label: 'Continuer',
                                isLoading: busy,
                                onPressed:
                                    busy ||
                                        !OnboardingValidators.canGoNext(
                                          state.currentStep,
                                          state.draft,
                                        )
                                    ? null
                                    : controller.next,
                              ),
                              if (state.isPhotoStep) ...[
                                const SizedBox(height: AppSpacing.xs),
                                AppButton(
                                  label: 'Passer',
                                  variant: AppButtonVariant.text,
                                  onPressed: busy
                                      ? null
                                      : () => _confirmSkipPhoto(controller),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
