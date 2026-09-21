import '../../../../core/error/result.dart';
import '../entities/app_notification.dart';

abstract class NotificationsRepository {
  Future<Result<List<AppNotification>>> fetchAll();
  Future<Result<void>> markRead(String id);
  Future<Result<void>> markAllRead();
}
