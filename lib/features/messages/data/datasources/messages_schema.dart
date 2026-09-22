/// Schéma messagerie M01 (PRD §19, addendum §2).
///
/// Colonnes réelles confirmées via export de schéma (2026-09-20) :
/// `conversation_participants(conversation_id, user_id, is_favorite,
/// last_read_at, joined_at, hidden_at)`, `conversations(id, created_at,
/// last_message_at, status, initiated_by, is_system_broadcast)`,
/// `messages(id, conversation_id, sender_id, type, content, status,
/// deleted_at, created_at, read_at)`, `message_attachments(id, message_id,
/// type, storage_path, url, file_name, size_bytes, duration_seconds,
/// mime_type)`, `matches(id, conversation_id,
/// requester_id, recipient_id, status, created_at, ...)`.
library;

const messagesParticipantIdColumns = ['user_id'];

/// D19 : `initiated_by` est la colonne réelle. Les alias ne sont lus
/// que s'ils arrivent déjà dans le row (un select qui les demande
/// casse tout le fallback si la colonne n'existe pas).
const messagesInitiatorColumns = [
  'initiated_by',
  'initiator_id',
  'created_by',
];

const messagesContentColumns = ['content'];

const messagesSenderColumns = ['sender_id', 'author_id'];

const messagesPreviewMaxChars = 80;

const messagesSystemPeerName = 'Agapeo';

const messagesMatchProposerColumns = ['requester_id'];
