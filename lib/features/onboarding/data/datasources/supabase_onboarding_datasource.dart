import 'dart:developer' as developer;
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_storage_buckets.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/supabase_exception_mapping.dart';
import '../../domain/mapping/onboarding_db_mapping.dart';
import 'onboarding_remote_datasource.dart';

/// Supabase writes for onboarding.
///
/// Colonnes `profiles` (schéma live) :
/// `gender`, `birth_date`, `country`, `church_denomination`,
/// `marital_status`, `why_marriage`, `onboarding_completed`, `hobbies`.
///
/// Photos : bucket Storage [AppStorageBuckets.avatars], table
/// `profile_photos` (`storage_path`, `is_primary`, `moderation_status` = `DRAFT`).
class SupabaseOnboardingDataSource implements OnboardingRemoteDataSource {
  SupabaseOnboardingDataSource(this._client);

  final SupabaseClient _client;

  static const _photosBucket = AppStorageBuckets.avatars;

  @override
  Future<void> updateProfileFields({
    required String genderDb,
    required DateTime birthDate,
    required String country,
    required String faithConfession,
    required String maritalStatusDb,
    required String whyMarriage,
    required bool onboardingCompleted,
    List<String> hobbies = const [],
  }) async {
    final userId = _requireUserId();
    try {
      await _client
          .from('profiles')
          .update(
            onboardingProfilesPatch(
              genderDb: genderDb,
              birthDate: birthDate,
              country: country,
              faithConfession: faithConfession,
              maritalStatusDb: maritalStatusDb,
              whyMarriage: whyMarriage,
              onboardingCompleted: onboardingCompleted,
              hobbies: hobbies,
            ),
          )
          .eq('id', userId);
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
  Future<void> uploadPhoto({
    required String localPath,
    required int slot,
    required bool isPrimary,
  }) async {
    final userId = _requireUserId();
    final file = File(localPath);
    if (!file.existsSync()) {
      throw const ValidationException('Fichier photo introuvable.');
    }

    final objectPath = '$userId/slot_$slot.jpg';
    final bytes = await file.length();
    developer.log(
      'Onboarding photo upload start — bucket="$_photosBucket" '
      'path="$objectPath" bytes=$bytes local="$localPath" primary=$isPrimary',
      name: 'onboarding.storage',
    );

    try {
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

      developer.log(
        'Onboarding photo upload ok — bucket="$_photosBucket" path="$objectPath"',
        name: 'onboarding.storage',
      );

      final url = _client.storage.from(_photosBucket).getPublicUrl(objectPath);

      final existing = await _client
          .from('profile_photos')
          .select('id')
          .eq('profile_id', userId)
          .eq('storage_path', objectPath)
          .maybeSingle();

      if (existing != null) {
        await _client
            .from('profile_photos')
            .update({
              'url': url,
              'is_primary': isPrimary,
              'moderation_status': 'DRAFT',
            })
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
          'url': url,
          'is_primary': isPrimary,
          'moderation_status': 'DRAFT',
        });
      }
    } on AuthException catch (e) {
      throw mapSupabaseAuthException(e);
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on StorageException catch (e) {
      throw mapStorageException(
        e,
        bucket: _photosBucket,
        objectPath: objectPath,
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

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const UnauthorizedException('Session expirée.');
    }
    return userId;
  }
}
