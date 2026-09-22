import '../../../../core/parsing/json.dart';
import '../../domain/entities/conversation_summary.dart';
import '../../domain/invite/incoming_invite.dart';
import '../../domain/invite/invite_list_preview.dart';
import '../../domain/preview/media_type_preview.dart';
import '../../domain/unread/unread_count.dart';
import '../datasources/messages_schema.dart';

class ConversationSummaryModel {
  const ConversationSummaryModel._();

  static ConversationSummary? fromAssembled({
    required Map<String, dynamic> conversation,
    required String currentUserId,
    Map<String, dynamic>? peer,
    Map<String, dynamic>? latestMessage,
    DateTime? lastReadAt,
    List<DateTime> incomingCreatedAts = const [],
  }) {
    final json = Json(conversation);
    final id = json.stringOrNull('id') ?? json.intOrNull('id')?.toString();
    if (id == null) return null;

    final status = json.string('status', fallback: 'ACCEPTED').toUpperCase();
    if (status == 'DECLINED') return null;

    final isSystem = json.boolValue('is_system_broadcast');
    final initiatorId =
        _firstString(json, messagesInitiatorColumns) ??
        _messageSender(latestMessage);
    final isIncomingInvite = isIncomingConversationInvite(
      status: status,
      currentUserId: currentUserId,
      initiatorId: initiatorId,
    );
    final lastAt =
        json.dateTime('last_message_at') ??
        _messageCreatedAt(latestMessage) ??
        json.dateTime('created_at');

    return ConversationSummary(
      id: id,
      peerName: isSystem ? messagesSystemPeerName : _displayName(peer),
      peerPhotoUrl: isSystem ? null : _httpPhoto(peer),
      preview: conversationListPreview(
        status: status,
        isIncomingInvite: isIncomingInvite,
        isSystem: isSystem,
        lastMessage: _previewSource(latestMessage),
        maxChars: messagesPreviewMaxChars,
      ),
      lastAt: lastAt,
      unreadCount: countUnreadMessages(
        lastReadAt: lastReadAt,
        incomingCreatedAts: incomingCreatedAts,
      ),
      status: status,
      isSystem: isSystem,
      isIncomingInvite: isIncomingInvite,
      peerId: isSystem
          ? null
          : (peer == null ? null : Json(peer).stringOrNull('id')),
    );
  }

  static String? _firstString(Json json, List<String> keys) {
    for (final key in keys) {
      final value = json.string(key).trim();
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  static String? _messageSender(Map<String, dynamic>? message) {
    if (message == null) return null;
    return _firstString(Json(message), messagesSenderColumns);
  }

  static DateTime? _messageCreatedAt(Map<String, dynamic>? message) {
    if (message == null) return null;
    return Json(message).dateTime('created_at');
  }

  static String? _previewSource(Map<String, dynamic>? message) {
    if (message == null) return null;
    final json = Json(message);
    if (json.dateTime('deleted_at') != null) return null;
    return conversationLastMessagePreview(
      type: json.stringOrNull('type'),
      content: _messageText(message),
      fileName: json.stringOrNull('file_name'),
    );
  }

  static String? _messageText(Map<String, dynamic>? message) {
    if (message == null) return null;
    final json = Json(message);
    if (json.dateTime('deleted_at') != null) return null;
    for (final key in messagesContentColumns) {
      final value = json.stringOrNull(key);
      if (value != null) return value;
    }
    return null;
  }

  static String _displayName(Map<String, dynamic>? peer) {
    if (peer == null) return '';
    final json = Json(peer);
    final first = json.stringOrNull('first_name');
    final last = json.stringOrNull('last_name');
    final parts = [if (first != null) first, if (last != null) last];
    final joined = parts.join(' ').trim();
    if (joined.isNotEmpty) return joined;
    return json.stringOrNull('display_name') ?? '';
  }

  static String? _httpPhoto(Map<String, dynamic>? peer) {
    if (peer == null) return null;
    final json = Json(peer);
    for (final key in ['photo_url', 'avatar_url']) {
      final value = json.stringOrNull(key);
      if (value != null &&
          (value.startsWith('http://') || value.startsWith('https://'))) {
        return value;
      }
    }
    final photos = peer['profile_photos'];
    if (photos is! List) return null;
    for (final photo in photos) {
      if (photo is! Map) continue;
      final fields = Json(Map<String, dynamic>.from(photo));
      for (final key in ['url', 'public_url']) {
        final value = fields.stringOrNull(key);
        if (value != null &&
            (value.startsWith('http://') || value.startsWith('https://'))) {
          return value;
        }
      }
    }
    return null;
  }
}
