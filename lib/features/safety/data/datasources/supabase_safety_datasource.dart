import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/supabase_exception_mapping.dart';
import '../../domain/report_reason.dart';

class SupabaseSafetyDataSource {
  SupabaseSafetyDataSource(this._client);

  final SupabaseClient _client;

  // `reports` : colonnes toujours non confirmées (hors du dump de schéma
  // reçu, table non atteinte). `blocks` confirmé (2026-09-20) :
  // blocker_id/blocked_id.
  static const _reportOwnerKeys = ['reporter_id', 'user_id', 'profile_id'];
  static const _reportTargetKeys = ['target_id', 'reported_id', 'profile_id'];
  static const _blockPairs = [('blocker_id', 'blocked_id')];

  Future<void> report({
    required ReportTargetType targetType,
    required String targetId,
    required ReportReason reason,
    String details = '',
  }) {
    return _guard(() async {
      final userId = _requireUserId();
      Object? last;
      for (final owner in _reportOwnerKeys) {
        for (final target in _reportTargetKeys) {
          if (owner == target) continue;
          try {
            await _client.from('reports').insert({
              owner: userId,
              target: targetId,
              'target_type': reportTargetDbValue(targetType),
              'reason': reason.dbValue,
              if (details.trim().isNotEmpty) 'details': details.trim(),
              'status': 'PENDING',
            });
            return;
          } on PostgrestException catch (e) {
            last = e;
            if (!_missing(e)) rethrow;
          }
        }
      }
      if (last is PostgrestException) throw last;
      throw const ServerException('Impossible d\'envoyer le signalement.');
    });
  }

  Future<void> block(String profileId) {
    return _guard(() async {
      final userId = _requireUserId();
      Object? last;
      for (final pair in _blockPairs) {
        try {
          await _client.from('blocks').insert({
            pair.$1: userId,
            pair.$2: profileId,
          });
          return;
        } on PostgrestException catch (e) {
          if (_unique(e)) return;
          last = e;
          if (!_missing(e)) rethrow;
        }
      }
      if (last is PostgrestException) throw last;
      throw const ServerException('Impossible de bloquer ce profil.');
    });
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
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
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const UnauthorizedException('Session expirée.');
    return id;
  }

  bool _missing(PostgrestException e) {
    final all = '${e.message} ${e.details} ${e.hint}'.toLowerCase();
    return (all.contains('column') && all.contains('does not exist')) ||
        all.contains('could not find');
  }

  bool _unique(PostgrestException e) {
    final all = '${e.message} ${e.details} ${e.code}'.toLowerCase();
    return e.code == '23505' ||
        all.contains('duplicate') ||
        all.contains('unique');
  }
}
