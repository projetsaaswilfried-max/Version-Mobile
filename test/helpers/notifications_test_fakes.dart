import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/notifications/domain/entities/app_notification.dart';
import 'package:agapeo/features/notifications/domain/repositories/notifications_repository.dart';

class FakeNotificationsRepository implements NotificationsRepository {
  FakeNotificationsRepository({this.items = const []});

  List<AppNotification> items;

  @override
  Future<Result<List<AppNotification>>> fetchAll() async => Ok(items);

  @override
  Future<Result<void>> markAllRead() async {
    items = [
      for (final item in items)
        AppNotification(
          id: item.id,
          title: item.title,
          body: item.body,
          createdAt: item.createdAt,
          isRead: true,
          category: item.category,
          aggregateCount: item.aggregateCount,
        ),
    ];
    return const Ok(null);
  }

  @override
  Future<Result<void>> markRead(String id) async => const Ok(null);
}
