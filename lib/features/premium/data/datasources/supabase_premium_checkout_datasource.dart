import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/supabase_exception_mapping.dart';

class SupabasePremiumCheckoutDataSource {
  SupabasePremiumCheckoutDataSource(this._client);

  final SupabaseClient _client;

  Future<Uri> startCheckout({String? plan}) {
    return _guard(() async {
      final token = _client.auth.currentSession?.accessToken;
      if (token == null) {
        throw const UnauthorizedException('Session expirée.');
      }
      final response = await _client.functions.invoke(
        'mobile-payment-handoff',
        headers: {'Authorization': 'Bearer $token'},
        body: plan == null ? null : {'plan': plan},
      );
      final data = response.data;
      final url = data is Map ? data['url'] as String? : null;
      if (url == null) {
        throw const ServerException('Réponse inattendue du serveur.');
      }
      return Uri.parse(url);
    });
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on FunctionsHttpException catch (e) {
      if (e.status == 401) {
        throw const UnauthorizedException('Session expirée.');
      }
      throw ServerException(
        'Impossible de préparer le paiement.',
        statusCode: e.status,
      );
    } on FunctionsFetchException {
      throw const NetworkException();
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
}
