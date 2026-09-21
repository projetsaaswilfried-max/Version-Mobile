import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../di/profile_providers.dart';
import '../../domain/entities/account_person.dart';
import 'account_people_state.dart';

class FavoritesController extends Notifier<AccountPeopleState> {
  @override
  AccountPeopleState build() {
    Future<void>.microtask(loadInitial);
    return const AccountPeopleState(isInitialLoading: true);
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isInitialLoading: true, clearError: true);
    final result = await ref
        .read(profileAccountRepositoryProvider)
        .fetchFavorites();
    if (!ref.mounted) return;
    switch (result) {
      case Ok<List<AccountPerson>>(:final value):
        state = state.copyWith(
          people: value,
          isInitialLoading: false,
          clearError: true,
        );
      case Err<List<AccountPerson>>(:final failure):
        state = state.copyWith(
          isInitialLoading: false,
          errorMessage: failure.message,
        );
    }
  }

  void search(String query) => state = state.copyWith(query: query);

  Future<void> remove(String id) async {
    await ref.read(profileAccountRepositoryProvider).removeFavorite(id);
    await loadInitial();
  }
}

class InterestedController extends Notifier<AccountPeopleState> {
  @override
  AccountPeopleState build() {
    Future<void>.microtask(loadInitial);
    return const AccountPeopleState(isInitialLoading: true);
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isInitialLoading: true, clearError: true);
    final result = await ref
        .read(profileAccountRepositoryProvider)
        .fetchInterested();
    if (!ref.mounted) return;
    switch (result) {
      case Ok<InterestedPeople>(:final value):
        state = state.copyWith(
          people: value.people,
          count: value.count,
          revealIdentities: value.revealIdentities,
          isInitialLoading: false,
          clearError: true,
        );
      case Err<InterestedPeople>(:final failure):
        state = state.copyWith(
          isInitialLoading: false,
          errorMessage: failure.message,
        );
    }
  }
}

class BlockedController extends Notifier<AccountPeopleState> {
  @override
  AccountPeopleState build() {
    Future<void>.microtask(loadInitial);
    return const AccountPeopleState(isInitialLoading: true);
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isInitialLoading: true, clearError: true);
    final result = await ref
        .read(profileAccountRepositoryProvider)
        .fetchBlocked();
    if (!ref.mounted) return;
    switch (result) {
      case Ok<List<AccountPerson>>(:final value):
        state = state.copyWith(
          people: value,
          isInitialLoading: false,
          clearError: true,
        );
      case Err<List<AccountPerson>>(:final failure):
        state = state.copyWith(
          isInitialLoading: false,
          errorMessage: failure.message,
        );
    }
  }

  Future<void> unblock(String id) async {
    await ref.read(profileAccountRepositoryProvider).unblock(id);
    await loadInitial();
  }
}

final favoritesControllerProvider =
    NotifierProvider.autoDispose<FavoritesController, AccountPeopleState>(
      FavoritesController.new,
    );

final interestedControllerProvider =
    NotifierProvider.autoDispose<InterestedController, AccountPeopleState>(
      InterestedController.new,
    );

final blockedControllerProvider =
    NotifierProvider.autoDispose<BlockedController, AccountPeopleState>(
      BlockedController.new,
    );
