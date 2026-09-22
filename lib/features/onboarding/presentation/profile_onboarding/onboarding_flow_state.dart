import 'package:equatable/equatable.dart';

import 'onboarding_draft.dart';

class OnboardingFlowState extends Equatable {
  const OnboardingFlowState({
    this.draft = const OnboardingDraft(),
    this.currentStep = 0,
    this.fieldErrors = const {},
    this.completedLocally = false,
    this.skippedPhoto = false,
    this.skippedHobbies = false,
    this.isSubmitting = false,
    this.submitError,
    this.essentialsLocked = false,
  });

  static const stepCount = 5;

  final OnboardingDraft draft;
  final int currentStep;
  final Map<String, String> fieldErrors;
  final bool completedLocally;
  final bool skippedPhoto;
  final bool skippedHobbies;
  final bool isSubmitting;
  final String? submitError;
  final bool essentialsLocked;

  bool get isLastStep => currentStep >= stepCount - 1;
  bool get isHobbiesStep => currentStep == 2;
  bool get isPhotoStep => currentStep == 3;
  bool get isRecapStep => currentStep == 4;

  OnboardingFlowState copyWith({
    OnboardingDraft? draft,
    int? currentStep,
    Map<String, String>? fieldErrors,
    bool? completedLocally,
    bool? skippedPhoto,
    bool? skippedHobbies,
    bool? isSubmitting,
    String? submitError,
    bool clearSubmitError = false,
    bool? essentialsLocked,
  }) {
    return OnboardingFlowState(
      draft: draft ?? this.draft,
      currentStep: currentStep ?? this.currentStep,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      completedLocally: completedLocally ?? this.completedLocally,
      skippedPhoto: skippedPhoto ?? this.skippedPhoto,
      skippedHobbies: skippedHobbies ?? this.skippedHobbies,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      essentialsLocked: essentialsLocked ?? this.essentialsLocked,
    );
  }

  @override
  List<Object?> get props => [
    draft,
    currentStep,
    fieldErrors,
    completedLocally,
    skippedPhoto,
    skippedHobbies,
    isSubmitting,
    submitError,
    essentialsLocked,
  ];
}
