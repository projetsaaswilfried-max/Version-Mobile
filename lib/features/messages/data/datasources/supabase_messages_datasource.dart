import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/supabase_exception_mapping.dart';
import '../../../../core/network/chunk_ids.dart';
import '../../../../core/parsing/json.dart';
import 'messages_remote_datasource.dart';
import 'messages_schema.dart';

class SupabaseMessagesDataSource implements MessagesRemoteDataSource {
  SupabaseMessagesDataSource(this._client);

  final SupabaseClient _client;

  static const _photosBucket = 'avatars';

  static const _conversationSelects = [
    'id, status, is_system_broadcast, updated_at, last_message_at, created_at, created_by, initiator_id, initiated_by',
    'id, status, is_system_broadcast, updated_at, created_at, created_by',
    'id, status, is_system_broadcast, updated_at, created_at',
    'id, status, is_system_broadcast, created_at',
    'id, status, created_at',
    'id, status',
  ];

  static const _messageSelects = [
    'id, conversation_id, content, body, text, created_at, sender_id, author_id, deleted_at',
    'id, conversation_id, content, created_at, sender_id, deleted_at',
    'id, conversation_id, body, created_at, sender_id',
    'id, conversation_id, content, created_at, author_id',
    'id, conversation_id, content, created_at',
  ];

  static const _profileSelects = [
    'id, first_name, last_name, photo_url, avatar_url, profile_photos(storage_path, url, is_primary)',
    'id, first_name, last_name, photo_url, avatar_url',
    'id, first_name, last_name, photo_url',
    'id, first_name, last_name',
  ];

  @override
  Future<String> fetchSubscriptionStatus() async {
    final userId = _requireUserId();
    try {
      final restricted = await _client
          .from('profile_restricted')
          .select('subscription_status')
          .eq('id', userId)
          .maybeSingle();
      if (restricted == null) return '';
      return (restricted['subscription_status'] as String?) ?? '';
    } on AuthException catch (e) {
      throw mapSupabaseAuthException(e);
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      throw mapUnknownSupabase(e);
    }
  }

  @override
  Future<String> currentUserId() async => _requireUserId();

  @override
  Future<List<AssembledConversationRow>> fetchConversationRows() async {
    final userId = _requireUserId();
    try {
      final mine = await _fetchMyParticipations(userId);
      if (mine.isEmpty) return const [];

      final conversationIds = <String>[];
      final lastReadByConversation = <String, DateTime?>{};
      for (final row in mine) {
        final id = _stringId(row, 'conversation_id');
        if (id == null) continue;
        conversationIds.add(id);
        lastReadByConversation[id] = Json(row).dateTime('last_read_at');
      }
      if (conversationIds.isEmpty) return const [];

      final conversations = await _fetchConversations(conversationIds);
      final othersByConversation = await _fetchPeerIds(
        conversationIds: conversationIds,
        currentUserId: userId,
      );
      final peerIds = othersByConversation.values.toSet().toList();
      final peers = await _fetchProfiles(peerIds);
      final messages = await _fetchMessages(conversationIds);

      return [
        for (final conversation in conversations)
          if (_stringId(conversation, 'id') case final id?)
            AssembledConversationRow(
              conversation: conversation,
              currentUserId: userId,
              peer: othersByConversation[id] == null
                  ? null
                  : peers[othersByConversation[id]!],
              latestMessage: _latestVisibleMessage(messages[id] ?? const []),
              lastReadAt: lastReadByConversation[id],
              incomingCreatedAts: _incomingAts(
                messages[id] ?? const [],
                userId,
              ),
            ),
      ];
    } on AuthException catch (e) {
      throw mapSupabaseAuthException(e);
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on UnauthorizedException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw mapUnknownSupabase(e);
    }
  }

  @override
  Future<AssembledConversationRow?> fetchConversationRow(String id) async {
    final rows = await fetchConversationRows();
    for (final row in rows) {
      final rowId = _stringId(row.conversation, 'id');
      if (rowId == id) return row;
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMessageRows(
    String conversationId,
  ) async {
    _requireUserId();
    try {
      final byConversation = await _fetchMessages([conversationId]);
      final rows = List<Map<String, dynamic>>.of(
        byConversation[conversationId] ?? const [],
      );
      rows.sort((a, b) {
        final aAt = Json(a).dateTime('created_at') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = Json(b).dateTime('created_at') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return aAt.compareTo(bAt);
      });
      return rows;
    } on AuthException catch (e) {
      throw mapSupabaseAuthException(e);
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      throw mapUnknownSupabase(e);
    }
  }

  @override
  Future<Map<String, dynamic>> insertTextMessage({
    required String conversationId,
    required String text,
  }) async {
    final userId = _requireUserId();
    try {
      final payloads = <Map<String, dynamic>>[
        {
          'conversation_id': conversationId,
          'content': text,
          'sender_id': userId,
          'type': 'TEXT',
        },
        {
          'conversation_id': conversationId,
          'content': text,
          'sender_id': userId,
        },
        {
          'conversation_id': conversationId,
          'body': text,
          'author_id': userId,
          'type': 'TEXT',
        },
      ];
      PostgrestException? lastMissing;
      for (final payload in payloads) {
        try {
          final row = await _client
              .from('messages')
              .insert(payload)
              .select()
              .single();
          return Map<String, dynamic>.from(row);
        } on PostgrestException catch (e) {
          if (_looksLikeMissingColumn(e)) {
            lastMissing = e;
            continue;
          }
          rethrow;
        }
      }
      throw lastMissing ??
          const ServerException('Impossible d\'envoyer le message.');
    } on AuthException catch (e) {
      throw mapSupabaseAuthException(e);
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on UnauthorizedException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw mapUnknownSupabase(e);
    }
  }

  @override
  Future<void> updateConversationStatus({
    required String conversationId,
    required String status,
  }) async {
    _requireUserId();
    try {
      await _client
          .from('conversations')
          .update({'status': status})
          .eq('id', conversationId);
    } on AuthException catch (e) {
      throw mapSupabaseAuthException(e);
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      throw mapUnknownSupabase(e);
    }
  }

  @override
  Future<void> hideParticipation(String conversationId) async {
    final userId = _requireUserId();
    try {
      PostgrestException? lastMissing;
      for (final column in messagesParticipantIdColumns) {
        try {
          await _client
              .from('conversation_participants')
              .update({
                'hidden_at': DateTime.now().toUtc().toIso8601String(),
              })
              .eq('conversation_id', conversationId)
              .eq(column, userId);
          return;
        } on PostgrestException catch (e) {
          if (_looksLikeMissingColumn(e)) {
            lastMissing = e;
            continue;
          }
          rethrow;
        }
      }
      throw lastMissing ??
          const ServerException('Impossible de masquer la discussion.');
    } on AuthException catch (e) {
      throw mapSupabaseAuthException(e);
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on UnauthorizedException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw mapUnknownSupabase(e);
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchActiveMatchRow(
    String conversationId,
  ) async {
    _requireUserId();
    try {
      final selects = [
        'id, conversation_id, status, proposer_id, initiated_by, requester_id, created_by, created_at',
        'id, conversation_id, status, proposer_id, created_at',
        'id, conversation_id, status, created_by, created_at',
        'id, conversation_id, status',
      ];
      PostgrestException? lastMissing;
      for (final select in selects) {
        try {
          final rows = await _client
              .from('matches')
              .select(select)
              .eq('conversation_id', conversationId)
              .inFilter('status', const ['PENDING', 'ACCEPTED'])
              .order('created_at', ascending: false)
              .limit(1);
          if (rows.isEmpty) return null;
          return Map<String, dynamic>.from(rows.first);
        } on PostgrestException catch (e) {
          if (_looksLikeMissingColumn(e)) {
            lastMissing = e;
            continue;
          }
          rethrow;
        }
      }
      throw lastMissing ??
          const ServerException('Impossible de lire le match.');
    } on AuthException catch (e) {
      throw mapSupabaseAuthException(e);
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on UnauthorizedException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw mapUnknownSupabase(e);
    }
  }

  @override
  Future<Map<String, dynamic>> insertMatchProposal(
    String conversationId,
  ) async {
    final userId = _requireUserId();
    try {
      final payloads = <Map<String, dynamic>>[
        {
          'conversation_id': conversationId,
          'proposer_id': userId,
          'status': 'PENDING',
        },
        {
          'conversation_id': conversationId,
          'initiated_by': userId,
          'status': 'PENDING',
        },
        {
          'conversation_id': conversationId,
          'requester_id': userId,
          'status': 'PENDING',
        },
        {
          'conversation_id': conversationId,
          'created_by': userId,
          'status': 'PENDING',
        },
      ];
      PostgrestException? lastMissing;
      for (final payload in payloads) {
        try {
          final row = await _client
              .from('matches')
              .insert(payload)
              .select()
              .single();
          return Map<String, dynamic>.from(row);
        } on PostgrestException catch (e) {
          if (_looksLikeMissingColumn(e)) {
            lastMissing = e;
            continue;
          }
          rethrow;
        }
      }
      throw lastMissing ??
          const ServerException('Impossible de proposer un match.');
    } on AuthException catch (e) {
      throw mapSupabaseAuthException(e);
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on UnauthorizedException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw mapUnknownSupabase(e);
    }
  }

  @override
  Future<Map<String, dynamic>> updateMatchStatus({
    required String matchId,
    required String status,
  }) async {
    _requireUserId();
    try {
      final row = await _client
          .from('matches')
          .update({'status': status})
          .eq('id', matchId)
          .select()
          .single();
      return Map<String, dynamic>.from(row);
    } on AuthException catch (e) {
      throw mapSupabaseAuthException(e);
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      throw mapUnknownSupabase(e);
    }
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const UnauthorizedException('Session expirée.');
    }
    return userId;
  }

  Future<List<Map<String, dynamic>>> _fetchMyParticipations(
    String userId,
  ) async {
    PostgrestException? lastMissing;
    for (final column in messagesParticipantIdColumns) {
      try {
        return await _fetchParticipationsForColumn(
          userId: userId,
          column: column,
        );
      } on PostgrestException catch (e) {
        if (_looksLikeMissingColumn(e)) {
          lastMissing = e;
          continue;
        }
        rethrow;
      }
    }
    throw lastMissing ??
        const ServerException('Impossible de lire les conversations.');
  }

  Future<List<Map<String, dynamic>>> _fetchParticipationsForColumn({
    required String userId,
    required String column,
  }) async {
    final selects = [
      'conversation_id, last_read_at, hidden_at, $column',
      'conversation_id, last_read_at, $column',
      'conversation_id, $column',
    ];
    PostgrestException? lastMissing;
    for (final select in selects) {
      try {
        final query = _client
            .from('conversation_participants')
            .select(select)
            .eq(column, userId);
        final rows = select.contains('hidden_at')
            ? await query.isFilter('hidden_at', null)
            : await query;
        return [
          for (final row in rows)
            if (Json(Map<String, dynamic>.from(row)).dateTime('hidden_at') ==
                null)
              Map<String, dynamic>.from(row),
        ];
      } on PostgrestException catch (e) {
        if (_looksLikeMissingColumn(e)) {
          lastMissing = e;
          continue;
        }
        rethrow;
      }
    }
    throw lastMissing ??
        const ServerException('Impossible de lire les conversations.');
  }

  Future<List<Map<String, dynamic>>> _fetchConversations(
    List<String> ids,
  ) async {
    PostgrestException? lastMissing;
    for (final select in _conversationSelects) {
      try {
        final rows = <Map<String, dynamic>>[];
        for (final chunk in chunkIds(ids)) {
          final page = await _client
              .from('conversations')
              .select(select)
              .inFilter('id', chunk);
          rows.addAll([for (final row in page) Map<String, dynamic>.from(row)]);
        }
        return rows;
      } on PostgrestException catch (e) {
        if (_looksLikeMissingColumn(e)) {
          lastMissing = e;
          continue;
        }
        rethrow;
      }
    }
    throw lastMissing ??
        const ServerException('Impossible de lire les conversations.');
  }

  Future<Map<String, String>> _fetchPeerIds({
    required List<String> conversationIds,
    required String currentUserId,
  }) async {
    PostgrestException? lastMissing;
    for (final column in messagesParticipantIdColumns) {
      try {
        final peers = <String, String>{};
        for (final chunk in chunkIds(conversationIds)) {
          final rows = await _client
              .from('conversation_participants')
              .select('conversation_id, $column')
              .inFilter('conversation_id', chunk);
          for (final row in rows) {
            final map = Map<String, dynamic>.from(row);
            final conversationId = _stringId(map, 'conversation_id');
            final profileId = _stringId(map, column);
            if (conversationId == null || profileId == null) continue;
            if (profileId == currentUserId) continue;
            peers.putIfAbsent(conversationId, () => profileId);
          }
        }
        return peers;
      } on PostgrestException catch (e) {
        if (_looksLikeMissingColumn(e)) {
          lastMissing = e;
          continue;
        }
        rethrow;
      }
    }
    throw lastMissing ??
        const ServerException('Impossible de lire les participants.');
  }

  Future<Map<String, Map<String, dynamic>>> _fetchProfiles(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return const {};
    PostgrestException? lastMissing;
    for (final select in _profileSelects) {
      try {
        final byId = <String, Map<String, dynamic>>{};
        for (final chunk in chunkIds(ids)) {
          final rows = await _client
              .from('profiles')
              .select(select)
              .inFilter('id', chunk);
          for (final row in rows) {
            final map = _applyPublicUrls(Map<String, dynamic>.from(row));
            final id = _stringId(map, 'id');
            if (id != null) byId[id] = map;
          }
        }
        await _fillMissingPhotos(byId);
        return byId;
      } on PostgrestException catch (e) {
        if (_looksLikeMissingColumn(e)) {
          lastMissing = e;
          continue;
        }
        rethrow;
      }
    }
    throw lastMissing ??
        const ServerException('Impossible de lire les profils.');
  }

  // L'embed imbriqué profiles->profile_photos ne remonte pas toujours de
  // résultat (même constat que Découvrir/Favoris) : on complète par une
  // requête directe pour les profils sans photo dans l'embed.
  Future<void> _fillMissingPhotos(Map<String, Map<String, dynamic>> byId) async {
    final missingIds = [
      for (final entry in byId.entries)
        if (!_hasEmbeddedPhoto(entry.value)) entry.key,
    ];
    if (missingIds.isEmpty) return;
    try {
      final rows = await _client
          .from('profile_photos')
          .select('profile_id, storage_path, url, is_primary')
          .inFilter('profile_id', missingIds);
      final byProfile = <String, Map<String, dynamic>>{};
      for (final row in rows) {
        final map = Map<String, dynamic>.from(row);
        final profileId = Json(map).stringOrNull('profile_id');
        if (profileId == null) continue;
        final isPrimary = Json(map).boolValue('is_primary');
        if (isPrimary || !byProfile.containsKey(profileId)) {
          byProfile[profileId] = map;
        }
      }
      for (final entry in byProfile.entries) {
        final profile = byId[entry.key];
        if (profile == null) continue;
        profile['profile_photos'] = [_publicPhotoFields(entry.value)];
      }
    } on PostgrestException {
      // Pas de photo de secours possible : le placeholder reste affiché.
    }
  }

  bool _hasEmbeddedPhoto(Map<String, dynamic> row) {
    final photos = row['profile_photos'];
    return photos is List && photos.isNotEmpty;
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchMessages(
    List<String> conversationIds,
  ) async {
    for (final select in _messageSelects) {
      try {
        final byConversation = <String, List<Map<String, dynamic>>>{};
        for (final chunk in chunkIds(conversationIds)) {
          final rows = await _client
              .from('messages')
              .select(select)
              .inFilter('conversation_id', chunk)
              .order('created_at', ascending: false);
          for (final row in rows) {
            final map = Map<String, dynamic>.from(row);
            final id = _stringId(map, 'conversation_id');
            if (id == null) continue;
            byConversation.putIfAbsent(id, () => []).add(map);
          }
        }
        return byConversation;
      } on PostgrestException catch (e) {
        if (_looksLikeMissingColumn(e)) continue;
        rethrow;
      }
    }
    return const {};
  }

  Map<String, dynamic>? _latestVisibleMessage(
    List<Map<String, dynamic>> messages,
  ) {
    for (final message in messages) {
      if (Json(message).dateTime('deleted_at') != null) continue;
      return message;
    }
    return null;
  }

  List<DateTime> _incomingAts(
    List<Map<String, dynamic>> messages,
    String currentUserId,
  ) {
    final ats = <DateTime>[];
    for (final message in messages) {
      final json = Json(message);
      if (json.dateTime('deleted_at') != null) continue;
      final sender = _firstString(json, messagesSenderColumns);
      if (sender == null || sender == currentUserId) continue;
      final at = json.dateTime('created_at');
      if (at != null) ats.add(at);
    }
    return ats;
  }

  String? _firstString(Json json, List<String> keys) {
    for (final key in keys) {
      final value = json.stringOrNull(key);
      if (value != null) return value;
    }
    return null;
  }

  String? _stringId(Map<String, dynamic> map, String key) {
    return Json(map).stringOrNull(key) ?? Json(map).intOrNull(key)?.toString();
  }

  Map<String, dynamic> _applyPublicUrls(Map<String, dynamic> row) {
    for (final key in ['photo_url', 'avatar_url']) {
      final value = row[key];
      if (value is String && value.isNotEmpty) {
        row[key] = _publicPhotoUrl(value);
      }
    }
    final photos = row['profile_photos'];
    if (photos is List) {
      row['profile_photos'] = [
        for (final photo in photos)
          if (photo is Map)
            _publicPhotoFields(Map<String, dynamic>.from(photo)),
      ];
    }
    return row;
  }

  Map<String, dynamic> _publicPhotoFields(Map<String, dynamic> photo) {
    for (final key in ['url', 'public_url', 'storage_path', 'path']) {
      final value = photo[key];
      if (value is String && value.isNotEmpty) {
        photo[key] = _publicPhotoUrl(value);
      }
    }
    return photo;
  }

  String _publicPhotoUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return _client.storage.from(_photosBucket).getPublicUrl(path);
  }

  bool _looksLikeMissingColumn(PostgrestException e) {
    final all = '${e.message} ${e.details} ${e.hint}'.toLowerCase();
    return (all.contains('column') && all.contains('does not exist')) ||
        all.contains('could not find') ||
        all.contains('relationship') ||
        all.contains('embedding');
  }
}
