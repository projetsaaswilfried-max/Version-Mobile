import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../di/profile_providers.dart';
import '../../domain/entities/more_info_details.dart';
import 'more_info_state.dart';

class MoreInfoController extends Notifier<MoreInfoState> {
  @override
  MoreInfoState build() {
    Future<void>.microtask(loadInitial);
    return const MoreInfoState(isInitialLoading: true);
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isInitialLoading: true, clearError: true);
    final result = await ref
        .read(profileAccountRepositoryProvider)
        .fetchMoreInfo();
    if (!ref.mounted) return;
    switch (result) {
      case Ok<MoreInfoDetails>(:final value):
        state = state.copyWith(
          details: value,
          isInitialLoading: false,
          clearError: true,
        );
      case Err<MoreInfoDetails>(:final failure):
        state = state.copyWith(
          isInitialLoading: false,
          errorMessage: failure.message,
        );
    }
  }

  void update(MoreInfoDetails Function(MoreInfoDetails current) update) {
    final current = state.details;
    if (current == null) return;
    state = state.copyWith(details: update(current), clearSaveError: true);
  }

  Future<bool> save() async {
    final current = state.details;
    if (current == null) return false;
    state = state.copyWith(isSaving: true, clearSaveError: true);
    final result = await ref.read(saveMoreInfoDetailsProvider)(current);
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

final moreInfoControllerProvider =
    NotifierProvider.autoDispose<MoreInfoController, MoreInfoState>(
      MoreInfoController.new,
    );
