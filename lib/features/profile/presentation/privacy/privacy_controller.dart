import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../di/profile_providers.dart';
import '../../domain/entities/privacy_settings.dart';
import 'privacy_state.dart';

class PrivacyController extends Notifier<PrivacyState> {
  @override
  PrivacyState build() {
    Future<void>.microtask(loadInitial);
    return const PrivacyState(isInitialLoading: true);
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isInitialLoading: true, clearError: true);
    final result = await ref
        .read(profileAccountRepositoryProvider)
        .fetchPrivacy();
    if (!ref.mounted) return;
    switch (result) {
      case Ok<PrivacySettings>(:final value):
        state = state.copyWith(
          settings: value,
          isInitialLoading: false,
          clearError: true,
        );
      case Err<PrivacySettings>(:final failure):
        state = state.copyWith(
          isInitialLoading: false,
          errorMessage: failure.message,
        );
    }
  }

  void toggle(String id, bool value) {
    final current = state.settings;
    if (current == null) return;
    state = state.copyWith(
      settings: current.toggling(id, value),
      clearSaveError: true,
    );
  }

  Future<bool> save() async {
    final current = state.settings;
    if (current == null) return false;
    state = state.copyWith(isSaving: true, clearSaveError: true);
    final result = await ref
        .read(profileAccountRepositoryProvider)
        .savePrivacy(current);
    if (!ref.mounted) return false;
    switch (result) {
      case Ok<void>():
        state = state.copyWith(isSaving: false, clearSaveError: true);
        return true;
      case Err<void>(:final failure):
        state = state.copyWith(isSaving: false, saveError: failure.message);
        return false;
    }
  }
}

final privacyControllerProvider =
    NotifierProvider.autoDispose<PrivacyController, PrivacyState>(
      PrivacyController.new,
    );
