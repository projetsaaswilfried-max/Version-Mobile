/// ATTENTION : flag de test manuel uniquement.
///
/// Passe TOUTES les vérifications d'abonnement Premium / vérification /
/// quota à "débloqué" (Découvrir : filtres, like, favori, invitation,
/// démasquage des identités ; post-login : plus de redirection EXPIRED).
/// Ne touche pas au flow de suspension ni à l'onboarding obligatoire.
///
/// À repasser à `false` avant tout commit destiné à rester sur une branche
/// partagée — grep `kBypassPremiumGatesForTesting` pour retrouver tous les
/// points d'usage.
const kBypassPremiumGatesForTesting = false;
