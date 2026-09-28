import '../../../../core/config/debug_flags.dart';
import '../../../profile/domain/entities/subscription_status.dart';

/// Qui voit le sheet Premium sur Découvrir (PRD §7 / §11).
bool shouldShowDiscoverPremiumSheet({
  required String subscriptionStatus,
  bool isStaff = false,
}) {
  if (kBypassPremiumGatesForTesting) return false;
  if (isStaff) return false;
  final status = parseSubscriptionStatus(subscriptionStatus);
  if (status == SubscriptionStatus.active) return false;
  // EXPIRED se comporte comme FREE (D42) - même bannière premium.
  return status == SubscriptionStatus.free ||
      status == SubscriptionStatus.canceled ||
      status == SubscriptionStatus.expired;
}

bool canUseDiscoverSearchFilters({
  required String subscriptionStatus,
  bool isStaff = false,
}) {
  if (kBypassPremiumGatesForTesting) return true;
  if (isStaff) return true;
  return parseSubscriptionStatus(subscriptionStatus) ==
      SubscriptionStatus.active;
}

/// Ouvrir une fiche complète : vérifié ou staff (PRD §3, Q1 — le Premium ne
/// gate que l'envoi de messages/invitations, pas la visibilité de profil).
bool canOpenDiscoverProfile({
  required bool visitorVerified,
  bool isStaff = false,
}) => kBypassPremiumGatesForTesting || isStaff || visitorVerified;

/// Like sur fiche D03 : profil vérifié ou staff (PRD D05).
bool canLikeDiscoverProfile({
  required bool visitorVerified,
  bool isStaff = false,
}) => kBypassPremiumGatesForTesting || isStaff || visitorVerified;

/// Favori sur fiche : vérifié ou staff (PRD §3/§7/§22 - Q1 : le favori n'a
/// aucun effet collatéral (quota, droit de contact, score), donc rien à
/// bypasser derrière Premium).
bool canFavoriteDiscoverProfile({
  required bool visitorVerified,
  bool isStaff = false,
}) => kBypassPremiumGatesForTesting || isStaff || visitorVerified;

/// Invitation sur fiche D06 : profil vérifié ou staff (PRD §18).
bool canInviteDiscoverProfile({
  required bool visitorVerified,
  bool isStaff = false,
}) => kBypassPremiumGatesForTesting || isStaff || visitorVerified;

/// Abonnement actif, sans aucune tolérance gratuite (D29) : envoyer une
/// invitation, écrire dans une conversation déjà acceptée.
bool isPremiumActive({required String subscriptionStatus, bool isStaff = false}) {
  if (kBypassPremiumGatesForTesting) return true;
  if (isStaff) return true;
  return parseSubscriptionStatus(subscriptionStatus) ==
      SubscriptionStatus.active;
}
