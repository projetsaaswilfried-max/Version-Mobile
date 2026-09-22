import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/conversation_match.dart';
import '../../domain/entities/conversation_summary.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/messages_repository.dart';

/// Conversations + messages fake tant que le schéma Supabase n'est pas figé.
class SeededMessagesRepository implements MessagesRepository {
  SeededMessagesRepository({DateTime? now}) {
    final n = now ?? DateTime.now();
    _conversations = List.of(seedConversations(now: n));
    _messagesByConv = {
      for (final entry in messageSeed(now: n).entries)
        entry.key: List.of(entry.value),
    };
    _matches = Map.of(matchSeed());
  }

  late List<ConversationSummary> _conversations;
  late Map<String, List<Message>> _messagesByConv;
  late Map<String, ConversationMatch> _matches;
  var _nextMessageId = 1000;

  static Map<String, ConversationMatch> matchSeed() => {
    'fake-accepted-1': ConversationMatch.none,
    'fake-accepted-2': const ConversationMatch(
      status: ConversationMatchStatus.pending,
      isIncoming: true,
    ),
  };

  static List<ConversationSummary> seedConversations({DateTime? now}) {
    final n = now ?? DateTime.now();
    return [
      ConversationSummary(
        id: 'fake-accepted-1',
        peerName: 'Léa Martin',
        peerId: 'peer-lea',
        preview: 'À dimanche après la messe ?',
        lastAt: n.subtract(const Duration(minutes: 12)),
        unreadCount: 2,
      ),
      ConversationSummary(
        id: 'fake-pending-1',
        peerName: 'Thomas Dubois',
        peerId: 'peer-thomas',
        preview: 'Souhaite discuter avec toi',
        lastAt: n.subtract(const Duration(hours: 3)),
        unreadCount: 1,
        status: 'PENDING',
        isIncomingInvite: true,
      ),
      ConversationSummary(
        id: 'fake-pending-out',
        peerName: 'Sophie Leroy',
        peerId: 'peer-sophie',
        preview: 'Invitation envoyée',
        lastAt: n.subtract(const Duration(hours: 5)),
        status: 'PENDING',
      ),
      ConversationSummary(
        id: 'fake-system-1',
        peerName: 'Agapeo',
        preview:
            'Bienvenue sur Agapeo. Prends le temps de compléter ton profil.',
        lastAt: n.subtract(const Duration(days: 1)),
        isSystem: true,
      ),
      ConversationSummary(
        id: 'fake-accepted-2',
        peerName: 'Camille Roux',
        peerId: 'peer-camille',
        preview: 'Merci pour ton message !',
        lastAt: n.subtract(const Duration(days: 2)),
      ),
    ];
  }

  /// Alias pour compat tests M01.
  static List<ConversationSummary> seed({DateTime? now}) =>
      seedConversations(now: now);

  static Map<String, List<Message>> messageSeed({DateTime? now}) {
    final n = now ?? DateTime.now();
    return {
      'fake-accepted-1': [
        Message(
          id: 'm1',
          conversationId: 'fake-accepted-1',
          type: MessageType.text,
          createdAt: n.subtract(const Duration(days: 1, hours: 2)),
          content: 'Bonjour Léa, ravi de faire ta connaissance.',
          senderIsMe: true,
        ),
        Message(
          id: 'm2',
          conversationId: 'fake-accepted-1',
          type: MessageType.text,
          createdAt: n.subtract(const Duration(days: 1, hours: 1)),
          content: 'Moi aussi ! Tu pratiques où ?',
        ),
        Message(
          id: 'm3',
          conversationId: 'fake-accepted-1',
          type: MessageType.image,
          createdAt: n.subtract(const Duration(hours: 20)),
          mediaLabel: 'Photo',
          mediaUrl: 'https://picsum.photos/seed/agapeo-m05/800/1200',
          senderIsMe: true,
        ),
        Message(
          id: 'm4',
          conversationId: 'fake-accepted-1',
          type: MessageType.video,
          createdAt: n.subtract(const Duration(hours: 18)),
          mediaLabel: 'Vidéo',
        ),
        Message(
          id: 'm5',
          conversationId: 'fake-accepted-1',
          type: MessageType.document,
          createdAt: n.subtract(const Duration(hours: 10)),
          fileName: 'programme-retraite.pdf',
          senderIsMe: true,
        ),
        Message(
          id: 'm6',
          conversationId: 'fake-accepted-1',
          type: MessageType.voice,
          createdAt: n.subtract(const Duration(hours: 8)),
          durationSeconds: 42,
        ),
        Message(
          id: 'm7',
          conversationId: 'fake-accepted-1',
          type: MessageType.text,
          createdAt: n.subtract(const Duration(hours: 6)),
          content: 'ancien',
          deleted: true,
          senderIsMe: true,
        ),
        Message(
          id: 'm8',
          conversationId: 'fake-accepted-1',
          type: MessageType.text,
          createdAt: n.subtract(const Duration(minutes: 12)),
          content: 'À dimanche après la messe ?',
        ),
      ],
      'fake-pending-1': [
        Message(
          id: 'p1',
          conversationId: 'fake-pending-1',
          type: MessageType.text,
          createdAt: n.subtract(const Duration(hours: 3)),
          content: 'Bonjour, j\'aimerais faire connaissance.',
        ),
      ],
      'fake-pending-out': const [],
      'fake-system-1': [
        Message(
          id: 's0',
          conversationId: 'fake-system-1',
          type: MessageType.system,
          createdAt: n.subtract(const Duration(days: 1, hours: 1)),
          content: 'Conversation avec Agapeo',
        ),
        Message(
          id: 's1',
          conversationId: 'fake-system-1',
          type: MessageType.text,
          createdAt: n.subtract(const Duration(days: 1)),
          content:
              'Bienvenue sur Agapeo. Prends le temps de compléter ton profil.',
        ),
      ],
      'fake-accepted-2': [
        Message(
          id: 'c1',
          conversationId: 'fake-accepted-2',
          type: MessageType.text,
          createdAt: n.subtract(const Duration(days: 2)),
          content: 'Merci pour ton message !',
        ),
      ],
    };
  }

  @override
  Future<Result<String>> fetchSubscriptionStatus() async => const Ok('FREE');

  @override
  Future<Result<List<ConversationSummary>>> fetchConversations() async =>
      Ok(List.unmodifiable(_conversations));

  @override
  Future<Result<ConversationSummary?>> fetchConversation(String id) async {
    for (final c in _conversations) {
      if (c.id == id) return Ok(c);
    }
    return const Ok(null);
  }

  @override
  Future<Result<List<Message>>> fetchMessages(String conversationId) async {
    final list = List<Message>.of(_messagesByConv[conversationId] ?? const []);
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return Ok(list);
  }

  @override
  Future<Result<Message>> sendText({
    required String conversationId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const Err(ValidationFailure('Message vide'));
    }
    final message = Message(
      id: 'local-${_nextMessageId++}',
      conversationId: conversationId,
      type: MessageType.text,
      createdAt: DateTime.now(),
      content: trimmed,
      senderIsMe: true,
    );
    _messagesByConv.putIfAbsent(conversationId, () => []).add(message);
    _updateConversationPreview(conversationId, trimmed, message.createdAt);
    return Ok(message);
  }

  @override
  Future<Result<Message>> sendImage({
    required String conversationId,
    required String localPath,
  }) async {
    final message = Message(
      id: 'local-${_nextMessageId++}',
      conversationId: conversationId,
      type: MessageType.image,
      createdAt: DateTime.now(),
      mediaLabel: 'Photo',
      mediaUrl: 'https://picsum.photos/seed/agapeo-$_nextMessageId/800/1200',
      senderIsMe: true,
    );
    _messagesByConv.putIfAbsent(conversationId, () => []).add(message);
    _updateConversationPreview(conversationId, 'Photo', message.createdAt);
    return Ok(message);
  }

  @override
  Future<Result<Message>> sendVoice({
    required String conversationId,
    required String localPath,
    required int durationSeconds,
  }) async {
    final message = Message(
      id: 'local-${_nextMessageId++}',
      conversationId: conversationId,
      type: MessageType.voice,
      createdAt: DateTime.now(),
      durationSeconds: durationSeconds,
      senderIsMe: true,
    );
    _messagesByConv.putIfAbsent(conversationId, () => []).add(message);
    _updateConversationPreview(conversationId, 'Audio', message.createdAt);
    return Ok(message);
  }

  @override
  Future<Result<void>> deleteMessage(String messageId) async {
    for (final entry in _messagesByConv.entries) {
      final index = entry.value.indexWhere((m) => m.id == messageId);
      if (index < 0) continue;
      final original = entry.value[index];
      if (!original.senderIsMe) {
        return const Err(ServerFailure('Impossible de supprimer ce message.'));
      }
      entry.value[index] = Message(
        id: original.id,
        conversationId: original.conversationId,
        type: original.type,
        createdAt: original.createdAt,
        senderIsMe: original.senderIsMe,
        deleted: true,
      );
      return const Ok(null);
    }
    return const Err(ServerFailure('Message introuvable.'));
  }

  @override
  Future<Result<void>> acceptInvitation(String conversationId) async {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index < 0) {
      return const Err(ServerFailure('Conversation introuvable.'));
    }
    final current = _conversations[index];
    _conversations[index] = ConversationSummary(
      id: current.id,
      peerName: current.peerName,
      peerPhotoUrl: current.peerPhotoUrl,
      preview: current.preview,
      lastAt: current.lastAt,
      unreadCount: current.unreadCount,
      status: 'ACCEPTED',
      isSystem: current.isSystem,
    );
    return const Ok(null);
  }

  @override
  Future<Result<void>> declineInvitation(String conversationId) async {
    _conversations.removeWhere((c) => c.id == conversationId);
    _messagesByConv.remove(conversationId);
    _matches.remove(conversationId);
    return const Ok(null);
  }

  @override
  Future<Result<ConversationMatch>> fetchMatch(String conversationId) async =>
      Ok(_matches[conversationId] ?? ConversationMatch.none);

  @override
  Future<Result<ConversationMatch>> proposeMatch(
    String conversationId, {
    required String recipientId,
  }) async {
    final next = const ConversationMatch(
      status: ConversationMatchStatus.pending,
    );
    _matches[conversationId] = next;
    return Ok(next);
  }

  @override
  Future<Result<ConversationMatch>> acceptMatch(String conversationId) async {
    final next = const ConversationMatch(
      status: ConversationMatchStatus.accepted,
    );
    _matches[conversationId] = next;
    return Ok(next);
  }

  @override
  Future<Result<ConversationMatch>> declineMatch(String conversationId) async {
    _matches[conversationId] = ConversationMatch.none;
    return const Ok(ConversationMatch.none);
  }

  @override
  Future<Result<ConversationMatch>> cancelMatch(String conversationId) async {
    _matches[conversationId] = ConversationMatch.none;
    return const Ok(ConversationMatch.none);
  }

  @override
  Future<Result<void>> hideConversation(String conversationId) async {
    _conversations.removeWhere((c) => c.id == conversationId);
    _messagesByConv.remove(conversationId);
    _matches.remove(conversationId);
    return const Ok(null);
  }

  @override
  Future<Result<void>> markConversationRead(String conversationId) async {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index < 0) return const Ok(null);
    final current = _conversations[index];
    _conversations[index] = ConversationSummary(
      id: current.id,
      peerName: current.peerName,
      peerId: current.peerId,
      peerPhotoUrl: current.peerPhotoUrl,
      preview: current.preview,
      lastAt: current.lastAt,
      unreadCount: 0,
      status: current.status,
      isSystem: current.isSystem,
      isIncomingInvite: current.isIncomingInvite,
    );
    return const Ok(null);
  }

  void _updateConversationPreview(
    String conversationId,
    String preview,
    DateTime lastAt,
  ) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index < 0) return;
    final current = _conversations[index];
    _conversations[index] = ConversationSummary(
      id: current.id,
      peerName: current.peerName,
      peerPhotoUrl: current.peerPhotoUrl,
      preview: preview,
      lastAt: lastAt,
      unreadCount: current.unreadCount,
      status: current.status,
      isSystem: current.isSystem,
      isIncomingInvite: current.isIncomingInvite,
    );
  }
}
