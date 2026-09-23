import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/supabase_exception_mapping.dart';
import '../../../../core/parsing/json.dart';
import '../../domain/mapping/resolve_verification_status.dart';
import 'profile_fields_remote_datasource.dart';

class SupabaseProfileFieldsDataSource implements ProfileFieldsRemoteDataSource {
  SupabaseProfileFieldsDataSource(this._client);

  static const _photosBucket = 'avatars';

  final SupabaseClient _client;

  @override
  Future<
    ({
      String? gender,
      String? birthDate,
      String? country,
      String? denomination,
      String? whyMarriage,
      String? maritalStatus,
      List<String> hobbies,
      bool hasPrimaryPhoto,
      String? firstName,
      String? lastName,
      String? photoVerificationStatus,
      String? primaryPhotoUrl,
    })
  >
  fetchFieldsRaw() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const UnauthorizedException('Session expirée.');
    }

    try {
      final profileFuture = _client
          .from('profiles')
          .select(
            'gender, birth_date, country, church_denomination, why_marriage, '
            'marital_status, hobbies, '
            'first_name, last_name, photo_verification_status',
          )
          .eq('id', userId)
          .maybeSingle();
      final photoFuture = _client
          .from('profile_photos')
          .select('storage_path, url')
          .eq('profile_id', userId)
          .eq('is_primary', true)
          .maybeSingle();
      final profile = await profileFuture;
      final photo = await photoFuture;

      // `profiles.photo_verification_status` n'est pas synchronisé au rejet
      // (reste bloqué à UNVERIFIED, confirmé par SQL direct) - la dernière
      // ligne de `verification_requests` fait foi tant qu'elle existe.
      String? verificationRequestStatus;
      try {
        final request = await _client
            .from('verification_requests')
            .select('status')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        verificationRequestStatus = Json(
          request ?? const {},
        ).stringOrNull('status');
      } on PostgrestException {
        verificationRequestStatus = null;
      }

      final json = Json(profile ?? const <String, dynamic>{});
      final resolvedStatus = resolveVerificationStatus(
        requestStatus: verificationRequestStatus,
        profileStatus: json.stringOrNull('photo_verification_status'),
      );
      return (
        gender: json.stringOrNull('gender'),
        birthDate: json.stringOrNull('birth_date'),
        country: json.stringOrNull('country'),
        denomination: json.stringOrNull('church_denomination'),
        whyMarriage: json.stringOrNull('why_marriage'),
        maritalStatus: json.stringOrNull('marital_status'),
        hobbies: json.stringList('hobbies'),
        hasPrimaryPhoto: photo != null,
        firstName: json.stringOrNull('first_name'),
        lastName: json.stringOrNull('last_name'),
        photoVerificationStatus: resolvedStatus,
        primaryPhotoUrl: _primaryPhotoUrl(photo),
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

  String? _primaryPhotoUrl(Map<String, dynamic>? photo) {
    if (photo == null) return null;
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
}
