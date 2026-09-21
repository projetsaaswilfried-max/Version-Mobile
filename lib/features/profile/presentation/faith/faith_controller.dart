import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../di/profile_providers.dart';
import '../../domain/entities/faith_details.dart';
import 'faith_state.dart';

class FaithController extends Notifier<FaithState> {
  @override
  FaithState build() {
    Future<void>.microtask(loadInitial);
    return const FaithState(isInitialLoading: true);
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isInitialLoading: true, clearError: true);
    final result = await ref
        .read(profileAccountRepositoryProvider)
        .fetchFaith();
    if (!ref.mounted) return;
    switch (result) {
      case Ok<FaithDetails>(:final value):
        state = state.copyWith(
          details: value,
          isInitialLoading: false,
          clearError: true,
        );
      case Err<FaithDetails>(:final failure):
        state = state.copyWith(
          isInitialLoading: false,
          errorMessage: failure.message,
        );
    }
  }

  void update(FaithDetails Function(FaithDetails current) update) {
    final current = state.details;
    if (current == null) return;
    state = state.copyWith(details: update(current), clearSaveError: true);
  }

  Future<bool> save() async {
    final current = state.details;
    if (current == null) return false;
    state = state.copyWith(isSaving: true, clearSaveError: true);
    final result = await ref.read(saveFaithDetailsProvider)(current);
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

final faithControllerProvider =
    NotifierProvider.autoDispose<FaithController, FaithState>(
      FaithController.new,
    );
