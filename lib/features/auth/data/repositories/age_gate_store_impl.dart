import '../../domain/repositories/age_gate_store.dart';
import '../datasources/age_gate_local_datasource.dart';

class AgeGateStoreImpl implements AgeGateStore {
  AgeGateStoreImpl(this._local);

  final AgeGateLocalDataSource _local;

  @override
  Future<bool> isAccepted() => _local.isAccepted();

  @override
  Future<void> accept() => _local.accept();
}
