/// Paires (propriétaire, cible) pour les tables de relation du hub compte.
///
/// Colonnes réelles confirmées via export de schéma (2026-09-20) :
/// `favorites(user_id, favorite_profile_id)`, `profile_likes(user_id,
/// liked_profile_id)`, `blocks(blocker_id, blocked_id)`.
class AccountRelationPairs {
  AccountRelationPairs._();

  static const favorites = <(String, String)>[('user_id', 'favorite_profile_id')];

  /// "Qui s'intéresse à moi" = lignes `profile_likes` où je suis la cible ;
  /// propriétaire du filtre = `liked_profile_id` (moi), colonne renvoyée =
  /// `user_id` (qui m'a aimé).
  static const likesReceived = <(String, String)>[('liked_profile_id', 'user_id')];

  static const blocks = <(String, String)>[('blocker_id', 'blocked_id')];
}

/// Colonne cible d'une ligne `select *` : UUID autre que le propriétaire.
String? inferRelationTargetColumn(
  Map<String, dynamic> row, {
  required String ownerCol,
}) {
  const skip = {'id', 'created_at', 'updated_at', 'inserted_at', 'deleted_at'};
  String? fallback;
  for (final entry in row.entries) {
    final key = entry.key;
    if (key == ownerCol || skip.contains(key)) continue;
    final value = entry.value;
    if (value is! String || value.isEmpty) continue;
    fallback ??= key;
    if (_uuid.hasMatch(value)) return key;
  }
  return fallback;
}

final _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);
