import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/supabase_exception_mapping.dart';
import '../../../../core/parsing/json.dart';
import 'profile_gate_remote_datasource.dart';

class SupabaseProfileGateDataSource implements ProfileGateRemoteDataSource {
  SupabaseProfileGateDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<
    ({bool isSuspended, String subscriptionStatus, bool onboardingCompleted})
  >
  fetchGateRaw() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const UnauthorizedException('Session expirée.');
    }

    try {
      final results = await Future.wait([
        _client
            .from('profiles')
            .select('onboarding_completed')
            .eq('id', userId)
            .maybeSingle(),
        _client
            .from('profile_restricted')
            .select('is_suspended, subscription_status')
            .eq('id', userId)
            .maybeSingle(),
      ]);
      final profile = results[0];
      final restricted = results[1];

      final profileJson = Json(profile ?? const <String, dynamic>{});
      final restrictedJson = Json(restricted ?? const <String, dynamic>{});

      return (
        isSuspended: restrictedJson.boolValue('is_suspended'),
        subscriptionStatus: restrictedJson.string('subscription_status'),
        onboardingCompleted: profileJson.boolValue('onboarding_completed'),
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
}
