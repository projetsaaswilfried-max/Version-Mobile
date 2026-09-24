import '../../../../core/error/map_data_exception.dart';
import '../../../../core/error/result.dart';
import '../../domain/repositories/premium_checkout_repository.dart';
import '../datasources/supabase_premium_checkout_datasource.dart';

class PremiumCheckoutRepositoryImpl implements PremiumCheckoutRepository {
  PremiumCheckoutRepositoryImpl(this._remote);

  final SupabasePremiumCheckoutDataSource _remote;

  @override
  Future<Result<Uri>> startCheckout({String? plan}) async {
    try {
      return Ok(await _remote.startCheckout(plan: plan));
    } catch (error) {
      return Err(mapDataException(error));
    }
  }
}
