import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/di/providers.dart';
import '../../../core/error/result.dart';
import '../data/notification_owner_columns.dart';
import '../di/notifications_providers.dart';
import '../domain/entities/app_notification.dart';
import '../domain/notification_category.dart';
import 'notifications_state.dart';

class NotificationsController extends Notifier<NotificationsState> {
  var _loadGeneration = 0;

  @override
  NotificationsState build() {
    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        final channel = client
            .channel('notifications-$userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'notifications',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: notificationOwnerColumn,
                value: userId,
              ),
              callback: (_) {
                // Soft refresh - never flip isLoading (full-page spinner).
                if (ref.mounted) load(silent: true);
              },
            )
            .subscribe();
        ref.onDispose(() => client.removeChannel(channel));
      }
    } catch (_) {
      // Env non configuré (tests, dart-defines manquants) : pas de temps réel.
    }
    Future.microtask(load);
    return const NotificationsState(isLoading: true);
  }

  Future<void> load({bool silent = false}) async {
    final generation = ++_loadGeneration;
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    final result = await ref.read(notificationsRepositoryProvider).fetchAll();
    if (!ref.mounted || generation != _loadGeneration) return;
    switch (result) {
      case Ok<List<AppNotification>>(:final value):
        state = state.copyWith(
          items: value,
          isLoading: false,
          clearError: true,
        );
      case Err<List<AppNotification>>(:final failure):
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
    }
  }

  void setFilter(AppNotificationCategory filter) {
    state = state.copyWith(filter: filter);
  }

  Future<void> markRead(String id) async {
    final index = state.items.indexWhere((item) => item.id == id);
    if (index == -1 || state.items[index].isRead) return;
    final updated = [...state.items];
    updated[index] = updated[index].asRead();
    state = state.copyWith(items: updated);

    final result = await ref.read(notificationsRepositoryProvider).markRead(id);
    if (!ref.mounted) return;
    if (result is Err) {
      await load(silent: true);
    }
  }

  Future<void> markAllRead() async {
    if (state.unreadCount == 0) return;
    state = state.copyWith(
      items: [for (final item in state.items) item.asRead()],
    );
    final result = await ref
        .read(notificationsRepositoryProvider)
        .markAllRead();
    if (!ref.mounted) return;
    if (result is Err) {
      await load(silent: true);
    }
  }
}

final notificationsControllerProvider =
    NotifierProvider.autoDispose<NotificationsController, NotificationsState>(
      NotificationsController.new,
    );
