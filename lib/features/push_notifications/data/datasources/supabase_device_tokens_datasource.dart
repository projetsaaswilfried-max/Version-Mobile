import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/supabase_exception_mapping.dart';

class SupabaseDeviceTokensDataSource {
  SupabaseDeviceTokensDataSource(this._client);

  final SupabaseClient _client;

  Future<void> registerToken({
    required String token,
    required String platform,
  }) {
    return _guard(() async {
      final userId = _requireUserId();
      try {
        await _client.from('device_tokens').insert({
          'user_id': userId,
          'token': token,
          'platform': platform,
        });
      } on PostgrestException catch (e) {
        // `token` est UNIQUE et il n'y a pas de policy UPDATE (confirmé par
        // SQL) - un upsert est donc impossible. Un conflit ici veut dire
        // que ce token est déjà enregistré (même utilisateur, appel
        // redondant au refresh) : rien à faire, pas une vraie erreur.
        if (e.code != '23505') rethrow;
      }
    });
  }

  Future<void> deleteToken(String token) {
    return _guard(() async {
      final userId = _requireUserId();
      await _client
          .from('device_tokens')
          .delete()
          .eq('token', token)
          .eq('user_id', userId);
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
}
