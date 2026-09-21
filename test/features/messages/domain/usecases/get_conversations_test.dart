import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/messages/domain/entities/conversation_match.dart';
import 'package:agapeo/features/messages/domain/entities/conversation_summary.dart';
import 'package:agapeo/features/messages/domain/entities/message.dart';
import 'package:agapeo/features/messages/domain/entities/messages_inbox.dart';
import 'package:agapeo/features/messages/domain/repositories/messages_repository.dart';
import 'package:agapeo/features/messages/domain/usecases/get_conversations.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMessagesRepository implements MessagesRepository {
  Result<String> subscription = const Ok('FREE');
  Result<List<ConversationSummary>> conversations = const Ok([]);
  var fetchConversationsCalls = 0;

  @override
  Future<Result<String>> fetchSubscriptionStatus() async => subscription;

  @override
  Future<Result<List<ConversationSummary>>> fetchConversations() async {
    fetchConversationsCalls++;
    return conversations;
  }

  @override
  Future<Result<ConversationSummary?>> fetchConversation(String id) async =>
      const Ok(null);

  @override
  Future<Result<List<Message>>> fetchMessages(String conversationId) async =>
      const Ok([]);

  @override
  Future<Result<Message>> sendText({
    required String conversationId,
    required String text,
  }) async => Err(ServerFailure('unused'));

  @override
  Future<Result<void>> acceptInvitation(String conversationId) async =>
      const Ok(null);

  @override
  Future<Result<void>> declineInvitation(String conversationId) async =>
      const Ok(null);

  @override
  Future<Result<ConversationMatch>> fetchMatch(String conversationId) async =>
      const Ok(ConversationMatch.none);

  @override
  Future<Result<ConversationMatch>> proposeMatch(
    String conversationId,
  ) async => const Ok(ConversationMatch.none);

  @override
  Future<Result<ConversationMatch>> acceptMatch(String conversationId) async =>
      const Ok(ConversationMatch.none);

  @override
  Future<Result<ConversationMatch>> declineMatch(
    String conversationId,
  ) async => const Ok(ConversationMatch.none);

  @override
  Future<Result<ConversationMatch>> cancelMatch(String conversationId) async =>
      const Ok(ConversationMatch.none);

  @override
  Future<Result<void>> hideConversation(String conversationId) async =>
      const Ok(null);
}

void main() {
  test('EXPIRED returns empty inbox without fetching conversations', () async {
    final repo = _FakeMessagesRepository()..subscription = const Ok('EXPIRED');
    final result = await GetConversations(repo)();

    expect(repo.fetchConversationsCalls, 0);
    expect(result, isA<Ok<MessagesInbox>>());
    final inbox = (result as Ok<MessagesInbox>).value;
    expect(inbox.expired, isTrue);
    expect(inbox.conversations, isEmpty);
  });

  test('sorts by last activity descending', () async {
    final older = DateTime.utc(2026, 9, 1);
    final newer = DateTime.utc(2026, 9, 18);
    final repo = _FakeMessagesRepository()
      ..conversations = Ok([
        ConversationSummary(id: 'old', peerName: 'A', lastAt: older),
        ConversationSummary(id: 'new', peerName: 'B', lastAt: newer),
        const ConversationSummary(id: 'none', peerName: 'C'),
      ]);

    final result = await GetConversations(repo)();
    final inbox = (result as Ok<MessagesInbox>).value;
    expect(inbox.expired, isFalse);
    expect(inbox.conversations.map((c) => c.id), ['new', 'old', 'none']);
  });

  test('propagates visitor failure', () async {
    final repo = _FakeMessagesRepository()
      ..subscription = const Err(NetworkFailure('offline'));

    final result = await GetConversations(repo)();
    expect(result, isA<Err<MessagesInbox>>());
    expect((result as Err<MessagesInbox>).failure.message, 'offline');
  });
}
