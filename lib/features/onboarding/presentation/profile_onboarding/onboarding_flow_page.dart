import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import 'onboarding_flow_controller.dart';
import 'onboarding_flow_state.dart';
import 'steps/essentials_step.dart';
import 'steps/faith_step.dart';
import 'steps/photos_step.dart';
import 'steps/preferences_step.dart';
import 'steps/selfie_step.dart';

/// Local profile onboarding (O01–O05). No API writes.
class OnboardingFlowPage extends ConsumerStatefulWidget {
  const OnboardingFlowPage({super.key});

  @override
  ConsumerState<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends ConsumerState<OnboardingFlowPage> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onCompleted(OnboardingFlowState state) {
    final message = state.skippedVerification
        ? 'Profil terminé sans soumission (local).'
        : 'Profil prêt (hors ligne pour l\'instant).';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    Navigator.of(context).pop();
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
        _onCompleted(next);
      }
    });

    final state = ref.watch(onboardingFlowProvider);
    final controller = ref.read(onboardingFlowProvider.notifier);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (state.currentStep == 0) {
                        Navigator.of(context).maybePop();
                      } else {
                        controller.back();
                      }
                    },
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: colors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        for (var i = 0; i < OnboardingFlowState.stepCount; i++)
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              height: 4,
                              decoration: BoxDecoration(
                                color: i <= state.currentStep
                                    ? colors.primary
                                    : colors.border,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  EssentialsStep(),
                  PhotosStep(),
                  SelfieStep(),
                  FaithStep(),
                  PreferencesStep(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: AppButton(
                label: state.isLastStep ? 'Soumettre' : 'Suivant',
                onPressed: () {
                  if (state.isLastStep) {
                    controller.submit();
                  } else {
                    controller.next();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
