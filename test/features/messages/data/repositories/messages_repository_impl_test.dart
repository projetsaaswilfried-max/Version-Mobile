import 'package:agapeo/core/error/exceptions.dart';
import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/messages/data/datasources/messages_remote_datasource.dart';
import 'package:agapeo/features/messages/data/repositories/messages_repository_impl.dart';
import 'package:agapeo/features/messages/domain/entities/conversation_summary.dart';
import 'package:agapeo/features/messages/domain/entities/conversation_match.dart';
import 'package:agapeo/features/messages/domain/entities/message.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRemote implements MessagesRemoteDataSource {
  String subscriptionStatus = 'ACTIVE';
  String userId = 'me';
  Object? subscriptionError;
  Object? conversationsError;
  List<AssembledConversationRow> rows = const [];
  List<Map<String, dynamic>> messageRows = const [];
  Map<String, dynamic>? inserted;
  String? updatedStatus;
  String? hiddenId;

  @override
  Future<String> fetchSubscriptionStatus() async {
    if (subscriptionError != null) throw subscriptionError!;
    return subscriptionStatus;
  }

  @override
  Future<String> currentUserId() async => userId;

  @override
  Future<List<AssembledConversationRow>> fetchConversationRows() async {
    if (conversationsError != null) throw conversationsError!;
    return rows;
  }

  @override
  Future<AssembledConversationRow?> fetchConversationRow(String id) async {
    for (final row in rows) {
      if (row.conversation['id'] == id) return row;
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMessageRows(
    String conversationId,
  ) async => messageRows;

  @override
  Future<Map<String, dynamic>> insertTextMessage({
    required String conversationId,
    required String text,
  }) async {
    inserted = {
      'id': 'm-new',
      'conversation_id': conversationId,
      'content': text,
      'sender_id': userId,
      'type': 'TEXT',
      'created_at': '2026-09-19T12:00:00Z',
    };
    return inserted!;
  }

  @override
  Future<void> updateConversationStatus({
    required String conversationId,
    required String status,
  }) async {
    updatedStatus = status;
  }

  Map<String, dynamic>? activeMatch;
  Map<String, dynamic>? proposedMatch;
  String? updatedMatchId;
  String? updatedMatchStatus;

  @override
  Future<void> hideParticipation(String conversationId) async {
    hiddenId = conversationId;
  }

  @override
  Future<Map<String, dynamic>?> fetchActiveMatchRow(
    String conversationId,
  ) async => activeMatch;

  @override
  Future<Map<String, dynamic>> insertMatchProposal(
    String conversationId,
  ) async {
    proposedMatch = {
      'id': 'match-1',
      'conversation_id': conversationId,
      'status': 'PENDING',
      'proposer_id': userId,
    };
    activeMatch = proposedMatch;
    return proposedMatch!;
  }

  @override
  Future<Map<String, dynamic>> updateMatchStatus({
    required String matchId,
    required String status,
  }) async {
    updatedMatchId = matchId;
    updatedMatchStatus = status;
    activeMatch = {
      'id': matchId,
      'conversation_id': 'c1',
      'status': status,
      'proposer_id': userId,
    };
    return activeMatch!;
  }
}

void main() {
  test('reads EXPIRED from profile_restricted status', () async {
    final repo = MessagesRepositoryImpl(
      _FakeRemote()..subscriptionStatus = 'EXPIRED',
    );

    final result = await repo.fetchSubscriptionStatus();
    expect(result, isA<Ok<String>>());
    expect((result as Ok<String>).value, 'EXPIRED');
  });

  test('empty subscription status falls back to FREE', () async {
    final repo = MessagesRepositoryImpl(
      _FakeRemote()..subscriptionStatus = '  ',
    );
    final result = await repo.fetchSubscriptionStatus();
    expect((result as Ok<String>).value, 'FREE');
  });

  test('maps assembled rows to summaries', () async {
    final repo = MessagesRepositoryImpl(
      _FakeRemote()
        ..rows = [
          AssembledConversationRow(
            currentUserId: 'me',
            conversation: {
              'id': 'c1',
              'status': 'ACCEPTED',
              'updated_at': '2026-09-19T10:00:00Z',
            },
            peer: {'first_name': 'Léa', 'last_name': 'Martin'},
            latestMessage: {'content': 'Salut'},
          ),
        ],
    );

    final result = await repo.fetchConversations();
    final list = (result as Ok<List<ConversationSummary>>).value;
    expect(list, hasLength(1));
    expect(list.single.peerName, 'Léa Martin');
    expect(list.single.preview, 'Salut');
  });

  test('fetchMessages maps rows', () async {
    final repo = MessagesRepositoryImpl(
      _FakeRemote()
        ..messageRows = [
          {
            'id': 'm1',
            'conversation_id': 'c1',
            'content': 'Hello',
            'sender_id': 'me',
            'type': 'TEXT',
            'created_at': '2026-09-19T10:00:00Z',
          },
        ],
    );
    final result = await repo.fetchMessages('c1');
    final list = (result as Ok<List<Message>>).value;
    expect(list.single.content, 'Hello');
    expect(list.single.senderIsMe, isTrue);
  });

  test('sendText inserts and maps', () async {
    final remote = _FakeRemote();
    final repo = MessagesRepositoryImpl(remote);
    final result = await repo.sendText(conversationId: 'c1', text: 'Salut');
    expect((result as Ok<Message>).value.content, 'Salut');
    expect(remote.inserted?['content'], 'Salut');
  });

  test('accept / decline / hide delegate', () async {
    final remote = _FakeRemote();
    final repo = MessagesRepositoryImpl(remote);
    await repo.acceptInvitation('c1');
    expect(remote.updatedStatus, 'ACCEPTED');
    await repo.declineInvitation('c1');
    expect(remote.updatedStatus, 'DECLINED');
    await repo.hideConversation('c1');
    expect(remote.hiddenId, 'c1');
  });

  test('match propose / accept / cancel', () async {
    final remote = _FakeRemote();
    final repo = MessagesRepositoryImpl(remote);

    final proposed = await repo.proposeMatch('c1');
    expect((proposed as Ok).value.status, ConversationMatchStatus.pending);
    expect(remote.proposedMatch?['status'], 'PENDING');

    remote.activeMatch = {
      'id': 'match-1',
      'conversation_id': 'c1',
      'status': 'PENDING',
      'proposer_id': 'other',
    };
    final accepted = await repo.acceptMatch('c1');
    expect((accepted as Ok).value.status, ConversationMatchStatus.accepted);
    expect(remote.updatedMatchStatus, 'ACCEPTED');

    remote.activeMatch = {
      'id': 'match-1',
      'conversation_id': 'c1',
      'status': 'ACCEPTED',
      'proposer_id': 'me',
    };
    final cancelled = await repo.cancelMatch('c1');
    expect((cancelled as Ok).value, ConversationMatch.none);
    expect(remote.updatedMatchStatus, 'CANCELLED');
  });

  test('fetchMatch none when empty', () async {
    final result = await MessagesRepositoryImpl(_FakeRemote()).fetchMatch('c1');
    expect((result as Ok).value, ConversationMatch.none);
  });

  test('maps remote errors to failures', () async {
    final repo = MessagesRepositoryImpl(
      _FakeRemote()..subscriptionError = const NetworkException('offline'),
    );

    final result = await repo.fetchSubscriptionStatus();
    expect(result, isA<Err<String>>());
    expect((result as Err<String>).failure, isA<NetworkFailure>());
  });
}
