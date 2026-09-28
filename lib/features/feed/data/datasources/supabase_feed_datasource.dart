import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/supabase_exception_mapping.dart';
import '../../../../core/network/chunk_ids.dart';
import '../../domain/entities/feed_filter.dart';
import '../../domain/mapping/post_db_mapping.dart';
import '../comments/comment_author_attach.dart';
import 'feed_embed_selects.dart';
import 'feed_remote_datasource.dart';

class SupabaseFeedDataSource implements FeedRemoteDataSource {
  SupabaseFeedDataSource(this._client);

  final SupabaseClient _client;

  static const _avatarsBucket = 'avatars';

  String? _workingSelect;

  @override
  Future<List<Map<String, dynamic>>> fetchPosts({
    required FeedFilter filter,
    required int offset,
    required int limit,
  }) async {
    try {
      return await _query(
        filter: filter,
        offset: offset,
        limit: limit,
        orderPinned: true,
      );
    } on PostgrestException catch (e) {
      if (_looksLikeMissingColumn(e)) {
        return _query(
          filter: filter,
          offset: offset,
          limit: limit,
          orderPinned: false,
        );
      }
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

  Future<List<Map<String, dynamic>>> _query({
    required FeedFilter filter,
    required int offset,
    required int limit,
    required bool orderPinned,
    int selectIndex = 0,
  }) async {
    final selects = FeedEmbedSelects.posts;
    final select = _workingSelect ?? selects[selectIndex];
    var query = _client
        .from('posts')
        .select(select)
        .eq('post_type', 'OFFICIAL');

    final category = filter.category;
    if (category != null) {
      query = query.eq('category', categoryToDb(category));
    }

    final ordered = orderPinned
        ? query
              .order('is_pinned', ascending: false)
              .order('created_at', ascending: false)
        : query.order('created_at', ascending: false);

    try {
      final rows = await ordered.range(offset, offset + limit - 1);
      _workingSelect = select;
      return _hydratePostAuthors([
        for (final row in rows) Map<String, dynamic>.from(row),
      ]);
    } on PostgrestException catch (e) {
      if (_workingSelect != null) rethrow;
      if (_looksLikeBadEmbed(e) && selectIndex < selects.length - 1) {
        return _query(
          filter: filter,
          offset: offset,
          limit: limit,
          orderPinned: orderPinned,
          selectIndex: selectIndex + 1,
        );
      }
      rethrow;
    }
  }

  // L'embed imbriqué profiles->profile_photos ne remonte pas toujours de
  // résultat (même constat que Découvrir/Favoris/Messages) : on complète
  // par une requête directe pour les auteurs sans photo dans l'embed.
  Future<List<Map<String, dynamic>>> _hydratePostAuthors(
    List<Map<String, dynamic>> rows,
  ) async {
    final hydrated = [for (final row in rows) _hydrateAuthor(row)];

    final missingIds = <String>{};
    for (final row in hydrated) {
      final author = row['author'];
      if (author is! Map) continue;
      final avatarUrl = author['avatar_url'];
      final hasAvatar = avatarUrl is String && avatarUrl.isNotEmpty;
      final id = author['id'];
      if (!hasAvatar && id is String) missingIds.add(id);
    }
    if (missingIds.isEmpty) return hydrated;

    try {
      final photos = await _fetchCommentPhotos(missingIds.toList());
      final byProfile = <String, Map<String, dynamic>>{};
      for (final photo in photos) {
        final profileId = photo['profile_id'];
        if (profileId is! String) continue;
        if (photo['is_primary'] == true || !byProfile.containsKey(profileId)) {
          byProfile[profileId] = photo;
        }
      }
      for (final row in hydrated) {
        final author = row['author'];
        if (author is! Map) continue;
        final authorMap = Map<String, dynamic>.from(author);
        final fallback = byProfile[authorMap['id']];
        if (fallback == null) continue;
        final avatar = _resolveAvatar({
          ...authorMap,
          'profile_photos': [fallback],
        });
        if (avatar != null) authorMap['avatar_url'] = avatar;
        row['author'] = authorMap;
      }
    } on PostgrestException {
      // Pas de photo de secours possible : le placeholder reste affiché.
    }
    return hydrated;
  }

  Map<String, dynamic> _hydrateAuthor(Map<String, dynamic> row) {
    final author = row['author'] ?? row['profiles'] ?? row['profile'];
    if (author is Map) {
      final authorMap = Map<String, dynamic>.from(author);
      final avatar = _resolveAvatar(authorMap);
      if (avatar != null) {
        authorMap['avatar_url'] = avatar;
      }
      row['author'] = authorMap;
    }
    return row;
  }

  Map<String, dynamic> _hydrateCommentRow(Map<String, dynamic> row) {
    return _hydrateAuthor(normalizeCommentRow(row));
  }

  Future<Map<String, dynamic>> _hydrateComment(Map<String, dynamic> row) async {
    final list = await _withCommentAuthors([_hydrateCommentRow(row)]);
    return list.first;
  }

  Future<List<Map<String, dynamic>>> _withCommentAuthors(
    List<Map<String, dynamic>> rows,
  ) async {
    var next = rows;
    final missingProfiles = {
      ...missingCommentAuthorIds(next),
      ...missingCommentVerificationIds(next),
    }.toList();
    if (missingProfiles.isNotEmpty) {
      try {
        final profiles = await _fetchCommentProfiles(missingProfiles);
        next = mergeCommentAuthors(
          next,
          profiles,
        ).map(_hydrateCommentRow).toList();
      } on PostgrestException {
        // Photos may still attach below.
      }
    }
    final missingAvatars = missingCommentAvatarIds(next);
    if (missingAvatars.isEmpty) return next;
    try {
      final photos = await _fetchCommentPhotos(missingAvatars);
      return mergeCommentPhotos(next, photos).map(_hydrateCommentRow).toList();
    } on PostgrestException {
      return next;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCommentPhotos(
    List<String> profileIds,
  ) async {
    final rows = <Map<String, dynamic>>[];
    for (final chunk in chunkIds(profileIds)) {
      final batch = await _client
          .from('profile_photos')
          .select(
            'profile_id, storage_path, selfie_storage_path, url, is_primary',
          )
          .inFilter('profile_id', chunk);
      rows.addAll([for (final row in batch) Map<String, dynamic>.from(row)]);
    }
    return rows;
  }

  Future<List<Map<String, dynamic>>> _fetchCommentProfiles(
    List<String> ids,
  ) async {
    final rows = <Map<String, dynamic>>[];
    for (final chunk in chunkIds(ids)) {
      final batch = await _client
          .from('profiles')
          .select(
            'id, first_name, last_name, avatar_url, photo_verification_status',
          )
          .inFilter('id', chunk);
      rows.addAll([for (final row in batch) Map<String, dynamic>.from(row)]);
    }
    return rows;
  }

  String? _resolveAvatar(Map<String, dynamic> author) {
    final direct = author['avatar_url'] ?? author['photo_url'];
    if (direct is String && direct.isNotEmpty) {
      return _publicPhotoUrl(direct);
    }
    final photos = author['profile_photos'];
    if (photos is! List) return null;
    final maps = photos
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList();
    if (maps.isEmpty) return null;
    Map<String, dynamic> chosen = maps.first;
    for (final photo in maps) {
      if (photo['is_primary'] == true) {
        chosen = photo;
        break;
      }
    }
    final path =
        chosen['url'] ??
        chosen['public_url'] ??
        chosen['selfie_storage_path'] ??
        chosen['storage_path'] ??
        chosen['path'];
    if (path is! String || path.isEmpty) return null;
    return _publicPhotoUrl(path);
  }

  String _publicPhotoUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final normalized = path.replaceFirst(RegExp('^avatars/'), '');
    return _client.storage.from(_avatarsBucket).getPublicUrl(normalized);
  }

  bool _looksLikeBadEmbed(PostgrestException e) {
    final all = '${e.message} ${e.details} ${e.hint}'.toLowerCase();
    if (all.contains('is_pinned')) return false;
    return all.contains('relationship') ||
        all.contains('could not find') ||
        all.contains('embedding') ||
        all.contains('foreign key') ||
        (all.contains('column') && all.contains('does not exist'));
  }

  bool _looksLikeMissingColumn(PostgrestException e) {
    final msg = e.message.toLowerCase();
    return msg.contains('is_pinned') ||
        (msg.contains('column') && msg.contains('does not exist'));
  }

  @override
  Future<Set<String>> fetchLikedPostIds(List<String> postIds) {
    return _fetchEngagementIds('post_likes', postIds);
  }

  @override
  Future<Set<String>> fetchBookmarkedPostIds(List<String> postIds) {
    return _fetchEngagementIds('post_bookmarks', postIds);
  }

  @override
  Future<void> setPostLiked(String postId, {required bool liked}) {
    return _setEngagement('post_likes', postId, enabled: liked);
  }

  @override
  Future<void> setPostBookmarked(String postId, {required bool bookmarked}) {
    return _setEngagement('post_bookmarks', postId, enabled: bookmarked);
  }

  @override
  Future<void> recordPostView(String postId) async {
    try {
      _requireUserId();
      await _client.rpc('record_post_view', params: {'post_id': postId});
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

  String _requireUserId() {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const UnauthorizedException();
    return id;
  }

  Future<Set<String>> _fetchEngagementIds(
    String table,
    List<String> postIds,
  ) async {
    if (postIds.isEmpty) return {};
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return {};
    try {
      final rows = <Map<String, dynamic>>[];
      for (final chunk in chunkIds(postIds)) {
        final batch = await _client
            .from(table)
            .select('post_id')
            .eq('user_id', uid)
            .inFilter('post_id', chunk);
        rows.addAll(batch);
      }
      return {
        for (final row in rows)
          if (row['post_id'] is String) row['post_id'] as String,
      };
    } on PostgrestException {
      return {};
    } catch (e) {
      throw mapUnknownSupabase(e);
    }
  }

  Future<void> _setEngagement(
    String table,
    String postId, {
    required bool enabled,
  }) async {
    try {
      final uid = _requireUserId();
      if (enabled) {
        await _client.from(table).insert({'post_id': postId, 'user_id': uid});
      } else {
        await _client
            .from(table)
            .delete()
            .eq('post_id', postId)
            .eq('user_id', uid);
      }
    } on PostgrestException catch (e) {
      if (enabled && _isUniqueViolation(e)) return;
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

  static const _commentSelects = FeedEmbedSelects.comments;

  String? _workingCommentSelect;

  @override
  Future<List<Map<String, dynamic>>> fetchComments(String postId) async {
    try {
      return await _queryComments(postId);
    } on PostgrestException catch (e) {
      if (_looksLikeMissingColumn(e) || _looksLikeBadEmbed(e)) {
        return _queryComments(postId);
      }
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

  Future<List<Map<String, dynamic>>> _queryComments(
    String postId, {
    int selectIndex = 0,
  }) async {
    final selects = _commentSelects;
    final select = _workingCommentSelect ?? selects[selectIndex];
    final query = _client
        .from('post_comments')
        .select(select)
        .eq('post_id', postId);
    try {
      // `order()` par défaut sur `ascending: false` dans ce package
      // (postgrest 2.9.1) - sans `ascending: true` explicite, les
      // commentaires arrivaient du plus récent au plus ancien, donc une
      // réponse plus récente à un fil pouvait passer avant une réponse
      // plus ancienne du même fil (repéré sur un fil réel : "Merci" posté
      // après la réponse d'Équipe Agapeo, mais affiché avant).
      final rows = await query.order('created_at', ascending: true);
      _workingCommentSelect = select;
      final mapped = [for (final row in rows) Map<String, dynamic>.from(row)];
      return _withCommentAuthors(mapped.map(_hydrateCommentRow).toList());
    } on PostgrestException catch (e) {
      if (_workingCommentSelect != null) rethrow;
      if (_looksLikeBadEmbed(e) && selectIndex < selects.length - 1) {
        return _queryComments(postId, selectIndex: selectIndex + 1);
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> insertComment(
    String postId,
    String body, {
    String? parentId,
  }) async {
    try {
      final uid = _requireUserId();
      final payload = <String, dynamic>{
        'post_id': postId,
        'user_id': uid,
        'content': body,
        if (parentId != null) 'parent_comment_id': parentId,
      };
      try {
        final row = await _client
            .from('post_comments')
            .insert(payload)
            .select('id, content, created_at, user_id, parent_comment_id')
            .single();
        return _hydrateComment(Map<String, dynamic>.from(row));
      } on PostgrestException catch (e) {
        if (_looksLikeMissingColumn(e) && parentId != null) {
          payload.remove('parent_comment_id');
          payload['parent_id'] = parentId;
          final row = await _client
              .from('post_comments')
              .insert(payload)
              .select('id, content, created_at, user_id, parent_id')
              .single();
          return _hydrateComment(Map<String, dynamic>.from(row));
        }
        if (!_looksLikeBadEmbed(e) && !_looksLikeMissingColumn(e)) rethrow;
        return _hydrateComment({
          'id': 'local-$uid-${DateTime.now().microsecondsSinceEpoch}',
          'content': body,
          'user_id': uid,
          if (parentId != null) 'parent_comment_id': parentId,
        });
      }
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
  Future<void> recordPostShare(String postId) async {
    try {
      final uid = _requireUserId();
      await _client.from('post_shares').insert({
        'post_id': postId,
        'user_id': uid,
      });
    } on PostgrestException catch (e) {
      if (_isUniqueViolation(e)) return;
      if (_looksLikeMissingColumn(e) || _looksLikeBadEmbed(e)) return;
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

  static const _postMediaBucket = 'post-media';

  @override
  Future<List<Map<String, dynamic>>> fetchMyPosts() async {
    final uid = _requireUserId();
    return fetchPersonalPostsByAuthor(uid);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPersonalPostsByAuthor(
    String authorId,
  ) async {
    try {
      final select = _workingSelect ?? FeedEmbedSelects.posts.first;
      try {
        final rows = await _client
            .from('posts')
            .select(select)
            .eq('post_type', 'PERSONAL')
            .eq('author_id', authorId)
            .order('created_at', ascending: false);
        return await _hydratePostAuthors([
          for (final row in rows) Map<String, dynamic>.from(row),
        ]);
      } on PostgrestException catch (e) {
        if (!_looksLikeMissingColumn(e) && !_looksLikeBadEmbed(e)) rethrow;
        final rows = await _client
            .from('posts')
            .select('*, post_media(*)')
            .eq('post_type', 'PERSONAL')
            .eq('author_id', authorId)
            .order('created_at', ascending: false);
        return [for (final row in rows) Map<String, dynamic>.from(row)];
      }
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
  Future<Map<String, dynamic>> insertPersonalPost({
    required String body,
    required String mediaType,
  }) async {
    try {
      final uid = _requireUserId();
      final payload = {
        'author_id': uid,
        'post_type': 'PERSONAL',
        'content': body,
        'media_type': mediaType,
      };
      try {
        final row = await _client
            .from('posts')
            .insert(payload)
            .select()
            .single();
        return Map<String, dynamic>.from(row);
      } on PostgrestException catch (e) {
        if (!_looksLikeMissingColumn(e)) rethrow;
        payload.remove('media_type');
        final row = await _client
            .from('posts')
            .insert(payload)
            .select()
            .single();
        return Map<String, dynamic>.from(row);
      }
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
  Future<void> attachPersonalMedia({
    required String postId,
    required String localPath,
    required bool isVideo,
  }) async {
    final uid = _requireUserId();
    final file = File(localPath);
    if (!file.existsSync()) return;
    // L'extension réelle du fichier (ImagePicker.pickVideo renvoie souvent
    // .mov sur iOS, pas toujours .mp4) - la forcer à "mp4" mentait sur le
    // vrai conteneur et cassait la lecture côté ExoPlayer (sniff failure).
    final ext = feedMediaExtension(localPath, fallback: isVideo ? 'mp4' : 'jpg');
    final objectPath = '$uid/$postId.$ext';
    try {
      await _client.storage
          .from(_postMediaBucket)
          .upload(
            objectPath,
            file,
            fileOptions: FileOptions(
              upsert: true,
              contentType: isVideo ? feedVideoContentType(ext) : 'image/jpeg',
            ),
          );
      final url = _client.storage
          .from(_postMediaBucket)
          .getPublicUrl(objectPath);
      // Colonnes réelles confirmées via export de schéma : id, post_id, url,
      // storage_path, position - pas de media_type sur cette table (il vit
      // sur posts.media_type). L'inclure ici faisait échouer l'insert à
      // chaque fois (colonne inexistante), silencieusement avalé plus bas :
      // le média s'uploadait dans le bucket mais n'était jamais rattaché au
      // post, donc jamais affiché.
      await _client.from('post_media').insert({
        'post_id': postId,
        'storage_path': objectPath,
        'url': url,
      });
    } on StorageException catch (e) {
      throw mapUnknownSupabase(e);
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } catch (e) {
      throw mapUnknownSupabase(e);
    }
  }

  @override
  Future<Map<String, dynamic>> updatePersonalPost({
    required String postId,
    required String body,
  }) async {
    try {
      final uid = _requireUserId();
      final row = await _client
          .from('posts')
          .update({'content': body})
          .eq('id', postId)
          .eq('author_id', uid)
          .select()
          .single();
      return Map<String, dynamic>.from(row);
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
  Future<void> deletePersonalPost(String postId) async {
    try {
      final uid = _requireUserId();
      await _client
          .from('posts')
          .delete()
          .eq('id', postId)
          .eq('author_id', uid);
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

  bool _isUniqueViolation(PostgrestException e) {
    final code = e.code ?? '';
    final all = '${e.message} ${e.details} $code'.toLowerCase();
    return code == '23505' ||
        all.contains('duplicate') ||
        all.contains('unique');
  }
}

/// Extension réelle d'un chemin de fichier local (pas une extension forcée
/// arbitrairement) - `ImagePicker.pickVideo` renvoie souvent `.mov` sur iOS,
/// pas toujours `.mp4`.
String feedMediaExtension(String path, {required String fallback}) {
  final dot = path.lastIndexOf('.');
  if (dot == -1 || dot == path.length - 1) return fallback;
  final ext = path.substring(dot + 1).toLowerCase();
  // Garde-fou : un nom de fichier sans "vraie" extension (ex. un id UUID
  // contenant un point) ne doit pas être pris pour une extension.
  return RegExp(r'^[a-z0-9]{1,5}$').hasMatch(ext) ? ext : fallback;
}

String feedVideoContentType(String ext) {
  switch (ext) {
    case 'mov':
      return 'video/quicktime';
    case 'webm':
      return 'video/webm';
    case '3gp':
      return 'video/3gpp';
    case 'm4v':
      return 'video/x-m4v';
    case 'mkv':
      return 'video/x-matroska';
    default:
      return 'video/mp4';
  }
}
