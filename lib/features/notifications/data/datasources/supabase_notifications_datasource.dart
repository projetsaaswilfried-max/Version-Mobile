import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/supabase_exception_mapping.dart';
import '../../../../core/parsing/json.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/notification_category.dart';
import '../notification_owner_columns.dart';

class SupabaseNotificationsDataSource {
  SupabaseNotificationsDataSource(this._client);

  final SupabaseClient _client;

  Future<List<AppNotification>> fetchAll() {
    return _guard(() async {
      final userId = _requireUserId();
      final rows = await _client
          .from('notifications')
          .select()
          .eq(notificationOwnerColumn, userId)
          .order('created_at', ascending: false);
      return [for (final row in rows) _map(Map<String, dynamic>.from(row))];
    });
  }

  Future<void> markRead(String id) {
    return _guard(() async {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    });
  }

  Future<void> markAllRead() {
    return _guard(() async {
      final userId = _requireUserId();
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq(notificationOwnerColumn, userId)
          .eq('is_read', false);
    });
  }

  // Colonnes réelles confirmées via export de schéma (2026-09-21) :
  // id, recipient_id, actor_id, type, title, body, target_url, is_read,
  // created_at, aggregate_count.
  AppNotification _map(Map<String, dynamic> row) {
    final json = Json(row);
    final type = json.string('type');
    return AppNotification(
      id: json.string('id'),
      title: json.string('title', fallback: 'Notification'),
      body: json.stringOrNull('body') ?? '',
      createdAt: json.dateTime('created_at') ?? DateTime.now(),
      isRead: json.boolValue('is_read'),
      category: notificationCategoryFromType(type),
      aggregateCount: json.intValue('aggregate_count', fallback: 1),
      type: type,
      targetUrl: json.stringOrNull('target_url'),
      actorId: json.stringOrNull('actor_id'),
    );
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
