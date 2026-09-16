import '../../domain/repositories/intro_store.dart';
import '../datasources/intro_local_datasource.dart';

class IntroStoreImpl implements IntroStore {
  IntroStoreImpl(this._local);

  final IntroLocalDataSource _local;

  @override
  Future<bool> isSeen() => _local.isSeen();

  @override
  Future<void> markSeen() => _local.markSeen();
}
