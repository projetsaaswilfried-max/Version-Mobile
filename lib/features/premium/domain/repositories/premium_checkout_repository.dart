import '../../../../core/error/result.dart';

abstract class PremiumCheckoutRepository {
  /// Demande une URL de paiement web pré-authentifiée pour le membre courant
  /// (fonction Supabase `mobile-payment-handoff`). [plan] est un des codes
  /// `WEEKLY` / `HALF_MONTH` / `MONTHLY` / `QUARTERLY` - `null` laisse le
  /// membre choisir sa formule sur `/premium`.
  Future<Result<Uri>> startCheckout({String? plan});
}
