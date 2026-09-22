import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/media/crop_profile_image.dart';
import '../../../profile/di/profile_providers.dart';
import '../../di/onboarding_providers.dart';
import 'onboarding_draft.dart';
import 'onboarding_flow_state.dart';

class OnboardingFlowController extends Notifier<OnboardingFlowState> {
  final _picker = ImagePicker();
  bool Function() _isDisposed = () => false;

  @override
  OnboardingFlowState build() {
    var disposed = false;
    ref.onDispose(() => disposed = true);
    _isDisposed = () => disposed;
    Future.microtask(_hydrateFromServer);
    return const OnboardingFlowState();
  }

  Future<void> _hydrateFromServer() async {
    try {
      final result = await ref.read(profileFieldsProvider.future);
      if (_isDisposed()) return;
      switch (result) {
        case Ok(:final value):
          state = state.copyWith(
            draft: value.hydrateDraft(state.draft),
            essentialsLocked: value.essentialsLocked,
          );
        case Err(:final failure):
          if (failure is NetworkFailure) {
            state = state.copyWith(submitError: failure.message);
          }
      }
    } catch (_) {
      // Env non initialisé (tests) : pas un échec réseau.
    }
  }

  void updateDraft(OnboardingDraft Function(OnboardingDraft) transform) {
    var next = transform(state.draft);
    if (state.essentialsLocked) {
      next = next.copyWith(
        gender: state.draft.gender,
        birthDate: state.draft.birthDate,
        country: state.draft.country,
      );
    }
    final remaining = Map<String, String>.from(state.fieldErrors);
    final current = OnboardingValidators.errorsForStep(state.currentStep, next);
    remaining.removeWhere((key, _) => !current.containsKey(key));
    state = state.copyWith(
      draft: next,
      fieldErrors: remaining,
      completedLocally: false,
      skippedPhoto: false,
      skippedHobbies: false,
      clearSubmitError: true,
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

  void skipHobbies() {
    state = state.copyWith(skippedHobbies: true);
    next();
  }

  void goToStep(int step) {
    if (step < 0 || step >= state.currentStep) return;
    state = state.copyWith(currentStep: step, fieldErrors: const {});
  }

  void back() {
    if (state.currentStep == 0) return;
    state = state.copyWith(
      currentStep: state.currentStep - 1,
      fieldErrors: const {},
    );
  }

  bool _applySubmitErrors() {
    final errors = OnboardingValidators.errorsForSubmit(state.draft);
    if (errors.isEmpty) return false;
    state = state.copyWith(
      fieldErrors: errors,
      currentStep: OnboardingValidators.firstInvalidStep(state.draft),
    );
    return true;
  }

  Future<void> submit() async {
    if (state.isSubmitting) return;
    if (_applySubmitErrors()) return;
    if (state.draft.profilePhotoPath == null ||
        state.draft.profilePhotoPath!.isEmpty) {
      state = state.copyWith(submitError: 'Ajoute une photo pour terminer.');
      return;
    }
    state = state.copyWith(isSubmitting: true, clearSubmitError: true);
    final result = await ref.read(submitOnboardingProvider)(state.draft);
    if (_isDisposed()) return;
    switch (result) {
      case Ok():
        _invalidateCompleteness();
        state = state.copyWith(
          isSubmitting: false,
          completedLocally: true,
          skippedPhoto: false,
          fieldErrors: const {},
        );
      case Err(:final failure):
        developer.log(
          'Onboarding submit Err: ${failure.runtimeType} — ${failure.message}',
          name: 'onboarding.flow',
        );
        state = state.copyWith(
          isSubmitting: false,
          submitError: failure.message,
        );
    }
  }

  Future<void> skipPhoto() async {
    if (state.isSubmitting) return;
    if (_applySubmitErrors()) return;
    state = state.copyWith(isSubmitting: true, clearSubmitError: true);
    final result = await ref.read(finishWithoutVerificationProvider)(
      state.draft,
    );
    if (_isDisposed()) return;
    switch (result) {
      case Ok():
        _invalidateCompleteness();
        state = state.copyWith(
          isSubmitting: false,
          completedLocally: true,
          skippedPhoto: true,
          fieldErrors: const {},
        );
      case Err(:final failure):
        developer.log(
          'Onboarding skipPhoto Err: ${failure.runtimeType} — ${failure.message}',
          name: 'onboarding.flow',
        );
        state = state.copyWith(
          isSubmitting: false,
          submitError: failure.message,
        );
    }
  }

  Future<void> pickProfilePhoto(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      preferredCameraDevice: source == ImageSource.camera
          ? CameraDevice.front
          : CameraDevice.rear,
      imageQuality: 85,
    );
    if (file == null || _isDisposed()) return;
    final croppedPath = await cropProfileImage(file.path);
    if (croppedPath == null || _isDisposed()) return;
    addPhoto(croppedPath);
  }

  void addPhoto(String path) {
    // Onboarding: une seule photo - un nouveau choix remplace l'existante.
    updateDraft((d) => d.copyWith(photoPaths: [path]));
  }

  void removePhotoAt(int index) {
    final paths = [...state.draft.photoPaths];
    if (index < 0 || index >= paths.length) return;
    paths.removeAt(index);
    updateDraft((d) => d.copyWith(photoPaths: paths));
  }

  void _invalidateCompleteness() {
    try {
      ref.invalidate(profileFieldsProvider);
    } catch (_) {}
  }

  void clearProfilePhoto() {
    updateDraft((d) => d.copyWith(clearProfilePhoto: true));
  }
}

final onboardingFlowProvider =
    NotifierProvider.autoDispose<OnboardingFlowController, OnboardingFlowState>(
      OnboardingFlowController.new,
    );
