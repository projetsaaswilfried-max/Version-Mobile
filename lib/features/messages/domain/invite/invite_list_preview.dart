import '../preview/truncate_preview.dart';

/// Copy web (liste `/messages`) pour une invitation reçue.
const kIncomingInvitePreview = 'Souhaite discuter avec toi';

/// Titre du fil quand l'utilisateur est destinataire d'une invitation.
const kIncomingInviteTitle = 'Invitation reçue';

/// Copy liste pour une invitation envoyée, s'il n'y a pas encore de texte.
const kOutgoingInvitePreview = 'Invitation envoyée';

String incomingInviteHeadline(String? peerName) {
  final name = peerName?.trim() ?? '';
  if (name.isEmpty) return 'Cette personne souhaite discuter avec toi.';
  return '$name souhaite discuter avec toi.';
}

/// Aperçu d'une ligne de liste. Une invitation reçue n'affiche jamais le
/// dernier message : le web force toujours [kIncomingInvitePreview].
String? conversationListPreview({
  required String status,
  required bool isIncomingInvite,
  required bool isSystem,
  String? lastMessage,
  int maxChars = 80,
}) {
  final truncated = truncateConversationPreview(
    lastMessage,
    maxChars: maxChars,
  );
  if (isSystem) return truncated;
  if (status.trim().toUpperCase() != 'PENDING') return truncated;
  if (isIncomingInvite) return kIncomingInvitePreview;
  return truncated ?? kOutgoingInvitePreview;
}
