/// Tentatives RPC `create_conversation_with_participant`.
///
/// Params retenus (aucun schema web dans ce repo) :
/// 1. `participant_id` (nom de la RPC) puis `other_user_id`
/// 2. `message` si non vide ; retry sans `message` si PostgREST refuse l'arg
List<Map<String, dynamic>> discoverInvitationRpcParamAttempts({
  required String profileId,
  String? message,
}) {
  final trimmed = message?.trim();
  final withMessage = trimmed != null && trimmed.isNotEmpty;
  final keys = ['participant_id', 'other_user_id'];
  return [
    for (final key in keys) ...[
      {key: profileId, if (withMessage) 'message': trimmed},
      if (withMessage) {key: profileId},
    ],
  ];
}

/// Début du mois civil local (quota 3 invitations / mois, spec D06).
String discoverCalendarMonthStartIso(DateTime now) {
  final local = now.isUtc ? now.toLocal() : now;
  return DateTime(local.year, local.month, 1).toIso8601String();
}

/// Colonne initiateur sur `conversations` — confirmée via export de schéma
/// (2026-09-20).
const discoverInitiatorColumnFallbacks = ['initiated_by'];

const discoverMonthlyInvitationStatuses = ['PENDING', 'ACCEPTED'];
