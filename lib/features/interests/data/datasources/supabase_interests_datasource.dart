import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/supabase_exception_mapping.dart';
import '../../../../core/parsing/json.dart';
import '../../domain/entities/interest.dart';

class SupabaseInterestsDataSource {
  SupabaseInterestsDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Interest>> fetchAll() {
    return _guard(() async {
      final rows = await _client
          .from('interests')
          .select('id, name')
          .order('name');
      return (rows as List)
          .map(
            (row) => Json(row as Map<String, dynamic>),
          )
          .map((json) => Interest(id: json.string('id'), name: json.string('name')))
          .toList();
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
    } catch (e) {
      throw mapUnknownSupabase(e);
    }
  }
}
