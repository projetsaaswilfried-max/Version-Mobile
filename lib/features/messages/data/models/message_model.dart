import '../../../../core/parsing/json.dart';
import '../../domain/entities/message.dart';
import '../datasources/messages_schema.dart';

class MessageModel {
  const MessageModel._();

  static Message? fromRow({
    required Map<String, dynamic> row,
    required String currentUserId,
  }) {
    final json = Json(row);
    final id = json.stringOrNull('id') ?? json.intOrNull('id')?.toString();
    final conversationId =
        json.stringOrNull('conversation_id') ??
        json.intOrNull('conversation_id')?.toString();
    if (id == null || conversationId == null) return null;

    final createdAt = json.dateTime('created_at') ?? DateTime.now();
    final sender = _firstString(json, messagesSenderColumns);
    final typeRaw = (json.stringOrNull('type') ?? 'TEXT').toUpperCase();
    final deleted = json.dateTime('deleted_at') != null;

    String? content;
    for (final key in messagesContentColumns) {
      final value = json.stringOrNull(key);
      if (value != null) {
        content = value;
        break;
      }
    }

    return Message(
      id: id,
      conversationId: conversationId,
      type: _typeFrom(typeRaw),
      createdAt: createdAt,
      content: content,
      senderIsMe: sender != null && sender == currentUserId,
      deleted: deleted,
      mediaLabel: json.stringOrNull('media_label'),
      fileName: json.stringOrNull('file_name') ?? json.stringOrNull('filename'),
      durationSeconds: json.intOrNull('duration_seconds') ??
          json.intOrNull('duration'),
      mediaUrl: json.stringOrNull('media_url') ?? json.stringOrNull('url'),
    );
  }

  static MessageType _typeFrom(String raw) {
    return switch (raw) {
      'IMAGE' => MessageType.image,
      'VIDEO' => MessageType.video,
      'DOCUMENT' => MessageType.document,
      'VOICE' || 'AUDIO' => MessageType.voice,
      'SYSTEM' => MessageType.system,
      _ => MessageType.text,
    };
  }

  static String? _firstString(Json json, List<String> keys) {
    for (final key in keys) {
      final value = json.stringOrNull(key);
      if (value != null) return value;
    }
    return null;
  }
}
