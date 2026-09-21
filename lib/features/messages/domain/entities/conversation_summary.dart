import 'package:equatable/equatable.dart';

class ConversationSummary extends Equatable {
  const ConversationSummary({
    required this.id,
    required this.peerName,
    this.peerPhotoUrl,
    this.preview,
    this.lastAt,
    this.unreadCount = 0,
    this.status = 'ACCEPTED',
    this.isSystem = false,
    this.isIncomingInvite = false,
    this.peerId,
  });

  final String id;
  final String peerName;
  final String? peerPhotoUrl;
  final String? preview;
  final DateTime? lastAt;
  final int unreadCount;
  final String status;
  final bool isSystem;
  final bool isIncomingInvite;
  final String? peerId;

  @override
  List<Object?> get props => [
    id,
    peerName,
    peerPhotoUrl,
    preview,
    lastAt,
    unreadCount,
    status,
    isSystem,
    isIncomingInvite,
    peerId,
  ];
}
