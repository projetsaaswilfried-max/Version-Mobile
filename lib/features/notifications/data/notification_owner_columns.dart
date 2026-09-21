/// Destinataire de `notifications` : `recipient_id`.
///
/// `user_id` et `profile_id` n'existent pas sur cette table — confirmé
/// (le fallback `profile_id` était l'erreur affichée sur N01).
const notificationOwnerColumn = 'recipient_id';
