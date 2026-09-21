import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../auth/di/auth_providers.dart';
import '../../di/profile_providers.dart';
import '../../domain/entities/profile_hub.dart';
import 'profile_hub_state.dart';

class ProfileHubController extends Notifier<ProfileHubState> {
  @override
  ProfileHubState build() {
    Future<void>.microtask(loadInitial);
    return const ProfileHubState(isInitialLoading: true);
  }

  Future<void> loadInitial() => _load(refreshing: false);

  Future<void> retry() => _load(refreshing: false);

  Future<void> refresh() => _load(refreshing: true);

  Future<void> _load({required bool refreshing}) async {
    if (refreshing) {
      state = state.copyWith(isRefreshing: true, clearError: true);
    } else {
      state = state.copyWith(
        isInitialLoading: true,
        clearError: true,
        clearHub: true,
      );
    }

    final email = ref.read(authRepositoryProvider).currentSession?.email ?? '';
    final result = await ref.read(getProfileHubProvider)(fallbackEmail: email);
    if (!ref.mounted) return;
    switch (result) {
      case Ok<ProfileHub>(:final value):
        state = state.copyWith(
          hub: value,
          isInitialLoading: false,
          isRefreshing: false,
          clearError: true,
        );
      case Err<ProfileHub>(:final failure):
        if (refreshing && state.hub != null) {
          state = state.copyWith(isRefreshing: false, isInitialLoading: false);
        } else {
          state = state.copyWith(
            isInitialLoading: false,
            isRefreshing: false,
            clearHub: true,
            errorMessage: failure.message,
          );
        }
    }
  }
}

final profileHubControllerProvider =
    NotifierProvider.autoDispose<ProfileHubController, ProfileHubState>(
      ProfileHubController.new,
    );
