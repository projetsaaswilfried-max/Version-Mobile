import 'package:equatable/equatable.dart';

import 'onboarding_draft.dart';

class OnboardingFlowState extends Equatable {
  const OnboardingFlowState({
    this.draft = const OnboardingDraft(),
    this.currentStep = 0,
    this.fieldErrors = const {},
    this.completedLocally = false,
    this.skippedVerification = false,
  });

  static const stepCount = 5;

  final OnboardingDraft draft;
  final int currentStep;
  final Map<String, String> fieldErrors;
  final bool completedLocally;
  final bool skippedVerification;

  bool get isLastStep => currentStep >= stepCount - 1;

  OnboardingFlowState copyWith({
    OnboardingDraft? draft,
    int? currentStep,
    Map<String, String>? fieldErrors,
    bool? completedLocally,
    bool? skippedVerification,
  }) {
    return OnboardingFlowState(
      draft: draft ?? this.draft,
      currentStep: currentStep ?? this.currentStep,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      completedLocally: completedLocally ?? this.completedLocally,
      skippedVerification: skippedVerification ?? this.skippedVerification,
    );
  }

  @override
  List<Object?> get props => [
    draft,
    currentStep,
    fieldErrors,
    completedLocally,
    skippedVerification,
  ];
}
