import '../../../../core/error/failure.dart';
import '../../../../core/error/map_data_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/parsing/json.dart';
import '../../domain/entities/conversation_match.dart';
import '../../domain/entities/conversation_summary.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/messages_repository.dart';
import '../datasources/messages_remote_datasource.dart';
import '../models/conversation_match_model.dart';
import '../models/conversation_summary_model.dart';
import '../models/message_model.dart';

class MessagesRepositoryImpl implements MessagesRepository {
  MessagesRepositoryImpl(this._remote);

  final MessagesRemoteDataSource _remote;

  @override
  Future<Result<String>> fetchSubscriptionStatus() async {
    try {
      final raw = await _remote.fetchSubscriptionStatus();
      final trimmed = raw.trim();
      return Ok(trimmed.isEmpty ? 'FREE' : trimmed);
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<List<ConversationSummary>>> fetchConversations() async {
    try {
      final rows = await _remote.fetchConversationRows();
      return Ok(_mapRows(rows));
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<ConversationSummary?>> fetchConversation(String id) async {
    try {
      final row = await _remote.fetchConversationRow(id);
      if (row == null) return const Ok(null);
      return Ok(
        ConversationSummaryModel.fromAssembled(
          conversation: row.conversation,
          currentUserId: row.currentUserId,
          peer: row.peer,
          latestMessage: row.latestMessage,
          lastReadAt: row.lastReadAt,
          incomingCreatedAts: row.incomingCreatedAts,
        ),
      );
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<List<Message>>> fetchMessages(String conversationId) async {
    try {
      final userId = await _remote.currentUserId();
      final rows = await _remote.fetchMessageRows(conversationId);
      return Ok([
        for (final row in rows)
          if (MessageModel.fromRow(row: row, currentUserId: userId)
              case final message?)
            message,
      ]);
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<Message>> sendText({
    required String conversationId,
    required String text,
  }) async {
    try {
      final userId = await _remote.currentUserId();
      final row = await _remote.insertTextMessage(
        conversationId: conversationId,
        text: text,
      );
      final message = MessageModel.fromRow(row: row, currentUserId: userId);
      if (message == null) {
        return const Err(ServerFailure('Message envoyé mais illisible.'));
      }
      return Ok(message);
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<void>> acceptInvitation(String conversationId) async {
    try {
      await _remote.updateConversationStatus(
        conversationId: conversationId,
        status: 'ACCEPTED',
      );
      return const Ok(null);
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<void>> declineInvitation(String conversationId) async {
    try {
      await _remote.updateConversationStatus(
        conversationId: conversationId,
        status: 'DECLINED',
      );
      return const Ok(null);
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<ConversationMatch>> fetchMatch(String conversationId) async {
    try {
      final userId = await _remote.currentUserId();
      final row = await _remote.fetchActiveMatchRow(conversationId);
      if (row == null) return const Ok(ConversationMatch.none);
      return Ok(
        ConversationMatchModel.fromRow(row: row, currentUserId: userId),
      );
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<ConversationMatch>> proposeMatch(
    String conversationId,
  ) async {
    try {
      final userId = await _remote.currentUserId();
      final row = await _remote.insertMatchProposal(conversationId);
      return Ok(
        ConversationMatchModel.fromRow(row: row, currentUserId: userId),
      );
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<ConversationMatch>> acceptMatch(String conversationId) async {
    return _setMatchStatus(conversationId, 'ACCEPTED');
  }

  @override
  Future<Result<ConversationMatch>> declineMatch(
    String conversationId,
  ) async {
    final result = await _setMatchStatus(conversationId, 'CANCELLED');
    return switch (result) {
      Ok() => const Ok(ConversationMatch.none),
      Err(:final failure) => Err(failure),
    };
  }

  @override
  Future<Result<ConversationMatch>> cancelMatch(String conversationId) async {
    final result = await _setMatchStatus(conversationId, 'CANCELLED');
    return switch (result) {
      Ok() => const Ok(ConversationMatch.none),
      Err(:final failure) => Err(failure),
    };
  }

  Future<Result<ConversationMatch>> _setMatchStatus(
    String conversationId,
    String status,
  ) async {
    try {
      final userId = await _remote.currentUserId();
      final current = await _remote.fetchActiveMatchRow(conversationId);
      final matchId =
          current == null
          ? null
          : (Json(current).stringOrNull('id') ??
                Json(current).intOrNull('id')?.toString());
      if (matchId == null) {
        return const Ok(ConversationMatch.none);
      }
      final row = await _remote.updateMatchStatus(
        matchId: matchId,
        status: status,
      );
      return Ok(
        ConversationMatchModel.fromRow(row: row, currentUserId: userId),
      );
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<void>> hideConversation(String conversationId) async {
    try {
      await _remote.hideParticipation(conversationId);
      return const Ok(null);
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  List<ConversationSummary> _mapRows(List<AssembledConversationRow> rows) {
    return [
      for (final row in rows)
        if (ConversationSummaryModel.fromAssembled(
              conversation: row.conversation,
              currentUserId: row.currentUserId,
              peer: row.peer,
              latestMessage: row.latestMessage,
              lastReadAt: row.lastReadAt,
              incomingCreatedAts: row.incomingCreatedAts,
            )
            case final summary?)
          summary,
    ];
  }
}
