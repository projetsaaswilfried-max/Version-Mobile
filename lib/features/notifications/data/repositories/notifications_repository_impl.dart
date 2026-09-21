import '../../../../core/error/map_data_exception.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/supabase_notifications_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._remote);

  final SupabaseNotificationsDataSource _remote;

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<List<AppNotification>>> fetchAll() => _guard(_remote.fetchAll);

  @override
  Future<Result<void>> markRead(String id) =>
      _guard(() => _remote.markRead(id));

  @override
  Future<Result<void>> markAllRead() => _guard(_remote.markAllRead);
}
