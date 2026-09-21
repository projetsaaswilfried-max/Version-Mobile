import '../../../../core/error/result.dart';
import '../repositories/discover_repository.dart';

class CountMonthlyDiscoverInvitations {
  const CountMonthlyDiscoverInvitations(this._repo);

  final DiscoverRepository _repo;

  Future<Result<int>> call() => _repo.countMonthlyInvitations();
}
