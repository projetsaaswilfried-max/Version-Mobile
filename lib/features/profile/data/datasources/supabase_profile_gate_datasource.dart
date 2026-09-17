import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/parsing/json.dart';
import 'profile_gate_remote_datasource.dart';

class SupabaseProfileGateDataSource implements ProfileGateRemoteDataSource {
  SupabaseProfileGateDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<
      ({
        bool isSuspended,
        String subscriptionStatus,
        bool onboardingCompleted,
      })> fetchGateRaw() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const UnauthorizedException('Session expirée.');
    }

    try {
      final profile = await _client
          .from('profiles')
          .select('onboarding_completed')
          .eq('id', userId)
          .maybeSingle();

      final restricted = await _client
          .from('profile_restricted')
          .select('is_suspended, subscription_status')
          .eq('id', userId)
          .maybeSingle();

      final profileJson = Json(profile ?? const <String, dynamic>{});
      final restrictedJson = Json(restricted ?? const <String, dynamic>{});

      return (
        isSuspended: restrictedJson.boolValue('is_suspended'),
        subscriptionStatus: restrictedJson.string('subscription_status'),
        onboardingCompleted: profileJson.boolValue('onboarding_completed'),
      );
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      final msg = e.toString();
      if (msg.toLowerCase().contains('socket') ||
          msg.toLowerCase().contains('network')) {
        throw NetworkException(msg);
      }
      throw ServerException(msg);
    }
  }

  Exception _mapAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('network') || msg.contains('socket')) {
      return NetworkException(e.message);
    }
    if (e.statusCode == '401' ||
        msg.contains('jwt') ||
        msg.contains('session')) {
      return UnauthorizedException(
        e.message.trim().isEmpty ? 'Session expirée.' : e.message,
      );
    }
    return e.message.trim().isEmpty
        ? const ServerException('Une erreur serveur est survenue.')
        : ServerException(e.message);
  }

  Exception _mapPostgrestException(PostgrestException e) {
    final code = e.code;
    if (code == 'PGRST301' || code == '42501') {
      return UnauthorizedException(
        e.message.trim().isEmpty ? 'Session expirée.' : e.message,
      );
    }
    final msg = e.message.toLowerCase();
    if (msg.contains('network') || msg.contains('socket')) {
      return NetworkException(e.message);
    }
    return e.message.trim().isEmpty
        ? const ServerException('Une erreur serveur est survenue.')
        : ServerException(e.message);
  }
}
