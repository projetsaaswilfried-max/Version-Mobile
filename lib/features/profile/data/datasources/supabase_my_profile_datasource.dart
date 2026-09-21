import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/supabase_exception_mapping.dart';
import '../../../../core/parsing/json.dart';
import '../../domain/entities/my_profile.dart';
import '../../domain/entities/my_profile_photo.dart';
import 'my_profile_remote_datasource.dart';

class SupabaseMyProfileDataSource implements MyProfileRemoteDataSource {
  SupabaseMyProfileDataSource(this._client);

  static const _photosBucket = 'avatars';
  static const _baseSelect =
      'first_name, last_name, gender, birth_date, country, city, profession, bio, '
      'photo_verification_status, church_denomination, why_marriage, marital_status';
  static const _relocateCandidates = [
    'willing_to_relocate',
    'ready_to_relocate',
    'open_to_relocate',
  ];

  final SupabaseClient _client;
  String? _relocateColumn;

  @override
  Future<MyProfileRaw> fetchRaw() async {
    final userId = _requireUserId();
    try {
      final profile = await _fetchProfileRow(userId);
      final photos = await _fetchPhotos(userId);
      final json = Json(profile);
      final relocateCol = _relocateColumn;
      return MyProfileRaw(
        firstName: json.stringOrNull('first_name'),
        lastName: json.stringOrNull('last_name'),
        gender: json.stringOrNull('gender'),
        birthDate: json.stringOrNull('birth_date'),
        country: json.stringOrNull('country'),
        city: json.stringOrNull('city'),
        profession: json.stringOrNull('profession'),
        bio: json.stringOrNull('bio'),
        photoVerificationStatus: json.stringOrNull('photo_verification_status'),
        willingToRelocate: relocateCol == null
            ? false
            : json.boolValue(relocateCol),
        relocateAvailable: relocateCol != null,
        isPremium: await _isPremium(userId),
        photos: photos,
        denomination: json.stringOrNull('church_denomination') ?? '',
        whyMarriage: json.stringOrNull('why_marriage') ?? '',
        maritalStatusDb: json.stringOrNull('marital_status'),
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
  Future<void> save(MyProfile profile, {required bool savePhotos}) async {
    final userId = _requireUserId();
    try {
      final patch = <String, Object?>{
        'first_name': profile.firstName.trim(),
        'last_name': profile.lastName.trim(),
        'city': profile.city.trim(),
        'profession': profile.profession.trim(),
        'bio': profile.bio.trim(),
        'church_denomination': profile.denomination.trim(),
        'why_marriage': profile.whyMarriage.trim(),
      };
      final marital = profile.maritalStatusDb?.trim();
      if (marital != null && marital.isNotEmpty) {
        patch['marital_status'] = marital;
      }
      final relocateCol = _relocateColumn;
      if (profile.relocateAvailable && relocateCol != null) {
        patch[relocateCol] = profile.willingToRelocate;
      }
      await _client.from('profiles').update(patch).eq('id', userId);
      if (savePhotos) {
        await _syncPhotos(userId, profile.photos);
      }
    } on AuthException catch (e) {
      throw mapSupabaseAuthException(e);
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on StorageException catch (e) {
      throw ServerException(
        e.message.trim().isEmpty
            ? 'Impossible d\'envoyer la photo.'
            : e.message,
      );
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on ValidationException {
      rethrow;
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      throw mapUnknownSupabase(e);
    }
  }

  Future<Map<String, dynamic>> _fetchProfileRow(String userId) async {
    final columns = [..._relocateCandidates, null];
    Object? lastError;
    for (final col in columns) {
      final select = col == null ? _baseSelect : '$_baseSelect, $col';
      try {
        final row = await _client
            .from('profiles')
            .select(select)
            .eq('id', userId)
            .maybeSingle();
        _relocateColumn = col;
        return Map<String, dynamic>.from(row ?? const <String, dynamic>{});
      } on PostgrestException catch (e) {
        lastError = e;
        if (col == null || !_looksLikeMissingColumn(e)) rethrow;
      }
    }
    throw lastError ??
        const ServerException('Impossible de charger le profil.');
  }

  Future<List<MyProfilePhoto>> _fetchPhotos(String userId) async {
    final rows = await _client
        .from('profile_photos')
        .select('id, storage_path, url, is_primary')
        .eq('profile_id', userId);
    final photos = <MyProfilePhoto>[];
    final rest = <MyProfilePhoto>[];
    for (final row in rows) {
      final map = Map<String, dynamic>.from(row);
      final json = Json(map);
      final photo = MyProfilePhoto(
        id: json.stringOrNull('id') ?? map['id']?.toString(),
        publicUrl: _photoUrl(map),
      );
      if (json.boolValue('is_primary')) {
        photos.add(photo);
      } else {
        rest.add(photo);
      }
    }
    return [...photos, ...rest];
  }

  Future<void> _syncPhotos(String userId, List<MyProfilePhoto> photos) async {
    final existing = await _client
        .from('profile_photos')
        .select('id')
        .eq('profile_id', userId);
    final keep = photos.map((photo) => photo.id).whereType<String>().toSet();
    for (final row in existing) {
      final id = row['id']?.toString();
      if (id == null || keep.contains(id)) continue;
      await _client.from('profile_photos').delete().eq('id', id);
    }

    for (var i = 0; i < photos.length; i++) {
      final photo = photos[i];
      final isPrimary = i == 0;
      final local = photo.localPath;
      if (local != null && local.isNotEmpty) {
        await _uploadPhoto(
          userId: userId,
          localPath: local,
          slot: i,
          isPrimary: isPrimary,
        );
      } else if (photo.id != null) {
        await _client
            .from('profile_photos')
            .update({'is_primary': isPrimary})
            .eq('id', photo.id!);
      }
    }
  }

  Future<void> _uploadPhoto({
    required String userId,
    required String localPath,
    required int slot,
    required bool isPrimary,
  }) async {
    final file = File(localPath);
    if (!file.existsSync()) {
      throw const ValidationException('Fichier photo introuvable.');
    }
    final objectPath = '$userId/slot_$slot.jpg';
    await _client.storage
        .from(_photosBucket)
        .upload(
          objectPath,
          file,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );
    final existing = await _client
        .from('profile_photos')
        .select('id')
        .eq('profile_id', userId)
        .eq('storage_path', objectPath)
        .maybeSingle();
    if (existing != null) {
      await _client
          .from('profile_photos')
          .update({'is_primary': isPrimary, 'moderation_status': 'DRAFT'})
          .eq('id', existing['id']);
    } else {
      if (isPrimary) {
        await _client
            .from('profile_photos')
            .update({'is_primary': false})
            .eq('profile_id', userId);
      }
      await _client.from('profile_photos').insert({
        'profile_id': userId,
        'storage_path': objectPath,
        'is_primary': isPrimary,
        'moderation_status': 'DRAFT',
      });
    }
  }

  String? _photoUrl(Map<String, dynamic> photo) {
    for (final key in ['url', 'public_url', 'storage_path', 'path']) {
      final value = photo[key];
      if (value is String && value.isNotEmpty) {
        return _publicPhotoUrl(value);
      }
    }
    return null;
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

  Future<bool> _isPremium(String userId) async {
    try {
      final row = await _client
          .from('profile_restricted')
          .select('subscription_status')
          .eq('id', userId)
          .maybeSingle();
      return (row?['subscription_status'] as String? ?? '').toUpperCase() ==
          'ACTIVE';
    } on PostgrestException {
      return false;
    }
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const UnauthorizedException('Session expirée.');
    }
    return userId;
  }
}
