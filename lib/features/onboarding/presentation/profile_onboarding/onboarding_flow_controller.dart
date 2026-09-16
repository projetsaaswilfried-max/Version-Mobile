import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'onboarding_draft.dart';
import 'onboarding_flow_state.dart';

class OnboardingFlowController extends Notifier<OnboardingFlowState> {
  final _picker = ImagePicker();

  @override
  OnboardingFlowState build() => const OnboardingFlowState();

  void updateDraft(OnboardingDraft Function(OnboardingDraft) transform) {
    state = state.copyWith(
      draft: transform(state.draft),
      fieldErrors: const {},
      completedLocally: false,
      skippedVerification: false,
    );
  }

  bool next() {
    final errors = OnboardingValidators.errorsForStep(
      state.currentStep,
      state.draft,
    );
    if (errors.isNotEmpty) {
      state = state.copyWith(fieldErrors: errors);
      return false;
    }
    if (state.isLastStep) return false;
    state = state.copyWith(
      currentStep: state.currentStep + 1,
      fieldErrors: const {},
    );
    return true;
  }

  void back() {
    if (state.currentStep == 0) return;
    state = state.copyWith(
      currentStep: state.currentStep - 1,
      fieldErrors: const {},
    );
  }

  bool submit() {
    final errors = OnboardingValidators.errorsForStep(4, state.draft);
    if (errors.isNotEmpty) {
      state = state.copyWith(fieldErrors: errors);
      return false;
    }
    state = state.copyWith(completedLocally: true, skippedVerification: false);
    return true;
  }

  void finishWithoutSubmit() {
    state = state.copyWith(
      completedLocally: true,
      skippedVerification: true,
      fieldErrors: const {},
    );
  }

  Future<void> addPhoto() async {
    if (state.draft.photoPaths.length >= OnboardingDraft.maxFreePhotos) return;
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    updateDraft(
      (d) => d.copyWith(photoPaths: [...d.photoPaths, file.path]),
    );
  }

  void removePhoto(int index) {
    final paths = [...state.draft.photoPaths]..removeAt(index);
    updateDraft((d) => d.copyWith(photoPaths: paths));
  }

  Future<void> captureSelfie() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
    );
    if (file == null) return;
    updateDraft((d) => d.copyWith(selfiePath: file.path));
  }

  void clearSelfie() {
    updateDraft((d) => d.copyWith(clearSelfie: true));
  }
}

final onboardingFlowProvider =
    NotifierProvider.autoDispose<OnboardingFlowController, OnboardingFlowState>(
      OnboardingFlowController.new,
    );
