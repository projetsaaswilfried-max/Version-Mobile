import 'package:equatable/equatable.dart';

enum MessageType { text, image, video, document, voice, system }

class Message extends Equatable {
  const Message({
    required this.id,
    required this.conversationId,
    required this.type,
    required this.createdAt,
    this.content,
    this.senderIsMe = false,
    this.deleted = false,
    this.mediaLabel,
    this.fileName,
    this.durationSeconds,
    this.mediaUrl,
  });

  final String id;
  final String conversationId;
  final MessageType type;
  final DateTime createdAt;
  final String? content;
  final bool senderIsMe;
  final bool deleted;
  final String? mediaLabel;
  final String? fileName;
  final int? durationSeconds;
  final String? mediaUrl;

  @override
  List<Object?> get props => [
    id,
    conversationId,
    type,
    createdAt,
    content,
    senderIsMe,
    deleted,
    mediaLabel,
    fileName,
    durationSeconds,
    mediaUrl,
  ];
}

String messageDisplayText(Message message) {
  if (message.deleted) return 'Message supprimé';
  return message.content ?? '';
}
