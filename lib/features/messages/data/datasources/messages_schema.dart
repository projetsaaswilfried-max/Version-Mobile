/// Schéma messagerie M01 (PRD §19, addendum §2).
///
/// Colonnes réelles confirmées via export de schéma (2026-09-20) :
/// `conversation_participants(conversation_id, user_id, is_favorite,
/// last_read_at, joined_at, hidden_at)`, `conversations(id, created_at,
/// last_message_at, status, initiated_by, is_system_broadcast)`,
/// `messages(id, conversation_id, sender_id, type, content, status,
/// deleted_at, created_at, read_at, ...)`, `matches(id, conversation_id,
/// requester_id, recipient_id, status, created_at, ...)`.
library;

const messagesParticipantIdColumns = ['user_id'];

const messagesInitiatorColumns = ['initiated_by'];

const messagesContentColumns = ['content'];

const messagesSenderColumns = ['sender_id'];

const messagesActivityColumns = ['last_message_at'];

const messagesPreviewMaxChars = 80;

const messagesSystemPeerName = 'Agapeo';

const messagesMatchProposerColumns = ['requester_id'];
