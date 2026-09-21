import 'dart:developer' as developer;
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/supabase_exception_mapping.dart';
import 'discover_id_chunks.dart';
import 'discover_invitation_query.dart';
import 'discover_photo_errors.dart';
import 'discover_remote_datasource.dart';
import 'discover_select_cache.dart';

/// Select candidats : du plus riche au plus court.
/// Si une colonne confession/valeurs n'existe pas, PostgREST renvoie
/// `column does not exist` et on retombe sur le select suivant (score partiel).
class SupabaseDiscoverDataSource implements DiscoverRemoteDataSource {
  SupabaseDiscoverDataSource(this._client);

  final SupabaseClient _client;

  static const _photosBucket = 'avatars';

  static const _selects = [
    'id, first_name, last_name, gender, birth_date, city, country, profession, bio, height_cm, photo_verification_status, is_staff, is_matched, church_denomination, why_marriage, marital_status, spiritual_engagement, values, hobbies, qualities, favorite_verse, testimony, accepted_countries, accepted_age_min, accepted_age_max, accepted_marital, profile_photos(storage_path, url, is_primary)',
    'id, first_name, last_name, gender, birth_date, city, country, profession, bio, photo_verification_status, is_staff, is_matched, church_denomination, why_marriage, marital_status, spiritual_engagement, values, hobbies, accepted_countries, accepted_age_min, accepted_age_max, accepted_marital, profile_photos(storage_path, url, is_primary)',
    'id, first_name, last_name, gender, birth_date, city, country, photo_verification_status, is_staff, is_matched, church_denomination, why_marriage, marital_status, spiritual_engagement, values, hobbies, accepted_countries, accepted_age_min, accepted_age_max, accepted_marital, profile_photos(storage_path, url, is_primary)',
    'id, first_name, last_name, gender, birth_date, city, country, photo_verification_status, is_staff, is_matched, church_denomination, why_marriage, marital_status, profile_photos(storage_path, url, is_primary)',
    'id, first_name, last_name, gender, birth_date, city, country, photo_verification_status, is_staff, is_matched, church_denomination, why_marriage, profile_photos(storage_path, url, is_primary)',
    'id, first_name, last_name, gender, birth_date, city, country, photo_verification_status, is_staff, is_matched, church_denomination, why_marriage',
  ];

  final _selectCache = DiscoverSelectCache();

  // Colonnes réelles confirmées via export de schéma (2026-09-20).
  static const _likeUserColumn = 'user_id';
  static const _likeTargetColumn = 'liked_profile_id';
  static const _favoriteUserColumn = 'user_id';
  static const _favoriteProfileColumn = 'favorite_profile_id';

  @override
  Future<DiscoverVisitorRaw> fetchVisitorRaw() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const UnauthorizedException('Session expirée.');
    }

    try {
      final profile = await _fetchProfile(userId);
      final restricted = await _client
          .from('profile_restricted')
          .select('subscription_status')
          .eq('id', userId)
          .maybeSingle();
      final status = restricted == null
          ? ''
          : (restricted['subscription_status'] as String? ?? '');
      final hydrated = await _hydratePhotos([profile]);
      return DiscoverVisitorRaw(
        profile: hydrated.first,
        subscriptionStatus: status,
      );
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
  Future<Map<String, dynamic>> fetchProfileDetailRow(String profileId) async {
    if (_client.auth.currentUser?.id == null) {
      throw const UnauthorizedException('Session expirée.');
    }

    try {
      final profile = await _fetchProfile(profileId);
      final hydrated = await _hydratePhotos([profile]);
      return hydrated.first;
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
  Future<void> recordProfileView(String viewedProfileId) async {
    try {
      if (_client.auth.currentUser?.id == null) {
        throw const UnauthorizedException('Session expirée.');
      }
      // Paramètre RPC : `viewed_profile_id` (défaut plan D03). Aucune
      // signature prod (web/schema) n'est présente dans ce repo.
      await _client.rpc(
        'record_profile_view',
        params: {'viewed_profile_id': viewedProfileId},
      );
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on AuthException catch (e) {
      throw mapSupabaseAuthException(e);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      throw mapUnknownSupabase(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCandidateRows({
    required int offset,
    required int limit,
    String? search,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const UnauthorizedException('Session expirée.');
    }

    try {
      final rows = await _selectWithFallback(
        userId: userId,
        single: false,
        offset: offset,
        limit: limit,
        search: search,
      );
      return _hydratePhotos(rows);
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
  Future<bool> isProfileLiked(String profileId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const UnauthorizedException('Session expirée.');
    }

    try {
      final row = await _client
          .from('profile_likes')
          .select(_likeTargetColumn)
          .eq(_likeUserColumn, userId)
          .eq(_likeTargetColumn, profileId)
          .maybeSingle();
      return row != null;
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
  Future<Set<String>> fetchLikedProfileIds() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const UnauthorizedException('Session expirée.');
    }

    try {
      final rows = await _client
          .from('profile_likes')
          .select(_likeTargetColumn)
          .eq(_likeUserColumn, userId);
      return {
        for (final row in rows)
          if (row[_likeTargetColumn] is String)
            row[_likeTargetColumn] as String,
      };
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
  Future<Set<String>> fetchFavoritedProfileIds() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const UnauthorizedException('Session expirée.');
    }

    try {
      final rows = await _client
          .from('favorites')
          .select(_favoriteProfileColumn)
          .eq(_favoriteUserColumn, userId);
      return {
        for (final row in rows)
          if (row[_favoriteProfileColumn] is String)
            row[_favoriteProfileColumn] as String,
      };
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
  Future<void> likeProfile(String profileId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const UnauthorizedException('Session expirée.');
    }

    try {
      await _client.from('profile_likes').insert({
        _likeUserColumn: userId,
        _likeTargetColumn: profileId,
      });
    } on AuthException catch (e) {
      throw mapSupabaseAuthException(e);
    } on PostgrestException catch (e) {
      if (_isUniqueViolation(e)) return;
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
  Future<void> unlikeProfile(String profileId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const UnauthorizedException('Session expirée.');
    }

    try {
      await _client
          .from('profile_likes')
          .delete()
          .eq(_likeUserColumn, userId)
          .eq(_likeTargetColumn, profileId);
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
  Future<bool> isProfileFavorited(String profileId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const UnauthorizedException('Session expirée.');
    }

    try {
      final row = await _client
          .from('favorites')
          .select(_favoriteProfileColumn)
          .eq(_favoriteUserColumn, userId)
          .eq(_favoriteProfileColumn, profileId)
          .maybeSingle();
      return row != null;
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
  Future<void> favoriteProfile(String profileId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const UnauthorizedException('Session expirée.');
    }

    try {
      await _client.from('favorites').insert({
        _favoriteUserColumn: userId,
        _favoriteProfileColumn: profileId,
      });
    } on AuthException catch (e) {
      throw mapSupabaseAuthException(e);
    } on PostgrestException catch (e) {
      if (_isUniqueViolation(e)) return;
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
  Future<void> unfavoriteProfile(String profileId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const UnauthorizedException('Session expirée.');
    }

    try {
      await _client
          .from('favorites')
          .delete()
          .eq(_favoriteUserColumn, userId)
          .eq(_favoriteProfileColumn, profileId);
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
  Future<int> countMonthlyInvitations() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const UnauthorizedException('Session expirée.');
    }

    // Best-effort : PRD liste `conversations.status` et
    // `conversation_participants` sans colonne initiateur. On filtre
    // PENDING+ACCEPTED sur `created_by` puis `initiator_id` /
    // `initiated_by`, mois civil local, `created_at >= 1er`.
    // Erreur réelle → mapping Err (pas de soft-fail 0).
    final monthStart = discoverCalendarMonthStartIso(DateTime.now());
    PostgrestException? lastMissingColumn;
    try {
      for (final column in discoverInitiatorColumnFallbacks) {
        try {
          return await _client
              .from('conversations')
              .count(CountOption.exact)
              .eq(column, userId)
              .inFilter('status', discoverMonthlyInvitationStatuses)
              .gte('created_at', monthStart);
        } on PostgrestException catch (e) {
          if (_looksLikeMissingColumn(e)) {
            lastMissingColumn = e;
            continue;
          }
          rethrow;
        }
      }
      throw lastMissingColumn ??
          const ServerException('Impossible de compter les invitations.');
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
  Future<void> sendInvitation({
    required String profileId,
    String? message,
  }) async {
    try {
      if (_client.auth.currentUser?.id == null) {
        throw const UnauthorizedException('Session expirée.');
      }
      await _rpcCreateConversation(profileId: profileId, message: message);
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on AuthException catch (e) {
      throw mapSupabaseAuthException(e);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      throw mapUnknownSupabase(e);
    }
  }

  Future<void> _rpcCreateConversation({
    required String profileId,
    String? message,
  }) async {
    PostgrestException? lastUnknownArg;
    for (final params in discoverInvitationRpcParamAttempts(
      profileId: profileId,
      message: message,
    )) {
      try {
        await _client.rpc(
          'create_conversation_with_participant',
          params: params,
        );
        return;
      } on PostgrestException catch (e) {
        if (_looksLikeUnknownRpcArg(e)) {
          lastUnknownArg = e;
          continue;
        }
        rethrow;
      }
    }
    throw lastUnknownArg ?? const ServerException('Invitation impossible.');
  }

  bool _looksLikeUnknownRpcArg(PostgrestException e) {
    final code = e.code ?? '';
    final all = '${e.message} ${e.details} ${e.hint} $code'.toLowerCase();
    return code == 'PGRST202' ||
        (all.contains('could not find') && all.contains('function')) ||
        all.contains('schema cache');
  }

  bool _isUniqueViolation(PostgrestException e) {
    final code = e.code ?? '';
    final all = '${e.message} ${e.details} $code'.toLowerCase();
    return code == '23505' ||
        all.contains('duplicate') ||
        all.contains('unique');
  }

  Future<Map<String, dynamic>> _fetchProfile(String userId) async {
    final rows = await _selectWithFallback(userId: userId, single: true);
    if (rows.isEmpty) {
      throw const ServerException('Profil introuvable.');
    }
    return rows.first;
  }

  Future<List<Map<String, dynamic>>> _selectWithFallback({
    required String userId,
    required bool single,
    int selectIndex = 0,
    int offset = 0,
    int limit = 0,
    String? search,
  }) async {
    final select = _selectCache.get(single: single) ?? _selects[selectIndex];
    try {
      if (single) {
        final row = await _client
            .from('profiles')
            .select(select)
            .eq('id', userId)
            .maybeSingle();
        _selectCache.set(select, single: true);
        if (row == null) return const [];
        return [Map<String, dynamic>.from(row)];
      }
      // .order('id') rend le .range() déterministe entre deux pages —
      // sans ordre explicite, PostgREST ne garantit pas la même séquence
      // de lignes d'un appel à l'autre (pagination silencieusement cassée).
      var query = _client.from('profiles').select(select).neq('id', userId);
      final needle = _sanitizeSearch(search);
      if (needle != null) {
        query = query.or(
          'first_name.ilike.%$needle%,'
          'last_name.ilike.%$needle%,'
          'city.ilike.%$needle%',
        );
      }
      final rows = await query.order('id').range(offset, offset + limit - 1);
      _selectCache.set(select, single: false);
      return [for (final row in rows) Map<String, dynamic>.from(row)];
    } on PostgrestException catch (e) {
      final canFallback =
          shouldFallbackDiscoverSelect(
            message: e.message,
            code: e.code,
            details: e.details,
            hint: e.hint,
          ) &&
          selectIndex < _selects.length - 1;
      if (!canFallback) rethrow;
      _selectCache.clear(single: single);
      final failedIndex = _selects.indexOf(select);
      final nextIndex = failedIndex >= 0 ? failedIndex + 1 : selectIndex + 1;
      if (nextIndex >= _selects.length) rethrow;
      return _selectWithFallback(
        userId: userId,
        single: single,
        selectIndex: nextIndex,
        offset: offset,
        limit: limit,
        search: search,
      );
    }
  }

  /// Recherche Découvrir côté serveur (nom/ville) : on retire les
  /// caractères qui casseraient la syntaxe `.or(...)` de PostgREST
  /// (virgule, parenthèses) ou qui injecteraient des jokers `ilike`
  /// (`%`, `_`) non voulus par l'utilisateur.
  String? _sanitizeSearch(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final cleaned = trimmed.replaceAll(RegExp(r'[,()%_]'), ' ').trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  Future<List<Map<String, dynamic>>> _hydratePhotos(
    List<Map<String, dynamic>> rows,
  ) async {
    var next = [for (final row in rows) _applyPublicUrls(Map.of(row))];
    final missing = [
      for (final row in next)
        if (!_hasHttpPhoto(row) && row['id'] is String) row['id'] as String,
    ];
    if (missing.isEmpty) return next;

    final byId = <String, List<Map<String, dynamic>>>{};
    for (final chunk in chunkDiscoverIds(missing)) {
      try {
        final photos = await _client
            .from('profile_photos')
            .select('profile_id, storage_path, url, is_primary')
            .inFilter('profile_id', chunk);
        for (final photo in photos) {
          final map = Map<String, dynamic>.from(photo);
          final id = map['profile_id'] as String?;
          if (id == null) continue;
          byId.putIfAbsent(id, () => []).add(map);
        }
      } on PostgrestException catch (e) {
        if (!isOversizedPhotoChunkError(
          message: e.message,
          code: e.code,
          details: e.details,
        )) {
          rethrow;
        }
        developer.log(
          'photo chunk failed (${chunk.length}): ${e.message}',
          name: 'discover',
        );
      }
    }

    if (byId.isEmpty) return next;
    return [
      for (final row in next)
        _applyPublicUrls({
          ...row,
          if (row['id'] is String && byId[row['id']] != null)
            'profile_photos': byId[row['id'] as String],
        }),
    ];
  }

  Map<String, dynamic> _applyPublicUrls(Map<String, dynamic> row) {
    final photos = row['profile_photos'];
    if (photos is List) {
      row['profile_photos'] = [
        for (final photo in photos)
          if (photo is Map)
            _publicPhotoFields(Map<String, dynamic>.from(photo)),
      ];
    }
    for (final key in ['photo_url', 'avatar_url']) {
      final value = row[key];
      if (value is String && value.isNotEmpty) {
        row[key] = _publicPhotoUrl(value);
      }
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

  bool _hasHttpPhoto(Map<String, dynamic> row) {
    for (final key in ['photo_url', 'avatar_url']) {
      final value = row[key];
      if (value is String &&
          (value.startsWith('http://') || value.startsWith('https://'))) {
        return true;
      }
    }
    final photos = row['profile_photos'];
    if (photos is! List) return false;
    for (final photo in photos) {
      if (photo is! Map) continue;
      for (final key in ['url', 'public_url', 'storage_path', 'path']) {
        final value = photo[key];
        if (value is String &&
            (value.startsWith('http://') || value.startsWith('https://'))) {
          return true;
        }
      }
    }
    return false;
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
