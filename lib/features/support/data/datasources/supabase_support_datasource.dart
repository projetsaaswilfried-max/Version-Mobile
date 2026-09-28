import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/supabase_exception_mapping.dart';
import '../../../../core/parsing/json.dart';
import '../../domain/entities/support_ticket.dart';

class SupabaseSupportDataSource {
  SupabaseSupportDataSource(this._client);

  final SupabaseClient _client;

  Future<List<SupportTicket>> fetchTickets() {
    return _guard(() async {
      final userId = _requireUserId();
      List<dynamic> rows;
      try {
        rows = await _client
            .from('support_tickets')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);
      } on PostgrestException catch (e) {
        if (!_missing(e)) rethrow;
        rows = await _client
            .from('support_tickets')
            .select()
            .eq('profile_id', userId)
            .order('created_at', ascending: false);
      }
      return [for (final row in rows) _ticket(Map<String, dynamic>.from(row))];
    });
  }

  Future<List<SupportMessage>> fetchMessages(String ticketId) {
    return _guard(() async {
      final userId = _requireUserId();
      final rows = await _client
          .from('support_messages')
          .select()
          .eq('ticket_id', ticketId)
          .order('created_at');
      return [
        for (final row in rows)
          _message(Map<String, dynamic>.from(row), userId),
      ];
    });
  }

  Future<SupportTicket> openTicket({
    required String subject,
    required String message,
  }) {
    return _guard(() async {
      final userId = _requireUserId();
      Map<String, dynamic> inserted;
      try {
        inserted = await _client
            .from('support_tickets')
            .insert({
              'user_id': userId,
              'subject': subject.trim(),
              'status': 'OPEN',
            })
            .select()
            .single();
      } on PostgrestException catch (e) {
        if (!_missing(e)) rethrow;
        inserted = await _client
            .from('support_tickets')
            .insert({
              'profile_id': userId,
              'subject': subject.trim(),
              'status': 'OPEN',
            })
            .select()
            .single();
      }
      final ticket = _ticket(inserted);
      await sendMessage(ticketId: ticket.id, message: message);
      return ticket;
    });
  }

  Future<void> sendMessage({
    required String ticketId,
    required String message,
  }) {
    return _guard(() async {
      final userId = _requireUserId();
      final payload = {
        'ticket_id': ticketId,
        'content': message.trim(),
        'sender_id': userId,
      };
      try {
        await _client.from('support_messages').insert(payload);
      } on PostgrestException catch (e) {
        if (!_missing(e)) rethrow;
        await _client.from('support_messages').insert({
          'ticket_id': ticketId,
          'body': message.trim(),
          'user_id': userId,
        });
      }
    });
  }

  SupportTicket _ticket(Map<String, dynamic> row) {
    final json = Json(row);
    return SupportTicket(
      id: json.string('id'),
      subject: json.string('subject', fallback: json.string('title')),
      status: json.string('status', fallback: 'OPEN'),
      createdAt: json.dateTime('created_at') ?? DateTime.now(),
    );
  }

  SupportMessage _message(Map<String, dynamic> row, String userId) {
    final json = Json(row);
    final sender =
        json.stringOrNull('sender_id') ?? json.stringOrNull('user_id');
    return SupportMessage(
      id: json.string('id'),
      body: json.stringOrNull('content') ?? json.string('body'),
      createdAt: json.dateTime('created_at') ?? DateTime.now(),
      isMine: sender == userId,
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

  bool _missing(PostgrestException e) {
    final all = '${e.message} ${e.details} ${e.hint}'.toLowerCase();
    return (all.contains('column') && all.contains('does not exist')) ||
        all.contains('could not find');
  }
}
