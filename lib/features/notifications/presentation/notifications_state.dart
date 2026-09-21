import 'package:equatable/equatable.dart';

import '../domain/entities/app_notification.dart';
import '../domain/notification_category.dart';

class NotificationsState extends Equatable {
  const NotificationsState({
    this.items = const [],
    this.filter = AppNotificationCategory.all,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<AppNotification> items;
  final AppNotificationCategory filter;
  final bool isLoading;
  final String? errorMessage;

  List<AppNotification> get visible {
    return [
      for (final item in items)
        if (filter == AppNotificationCategory.all ||
            (filter == AppNotificationCategory.unread && !item.isRead) ||
            (filter != AppNotificationCategory.unread &&
                filter != AppNotificationCategory.all &&
                item.category == filter))
          item,
    ];
  }

  int get unreadCount => items.where((item) => !item.isRead).length;

  NotificationsState copyWith({
    List<AppNotification>? items,
    AppNotificationCategory? filter,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [items, filter, isLoading, errorMessage];
}
