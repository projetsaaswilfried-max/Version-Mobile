import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/messages/domain/entities/conversation_match.dart';
import 'package:agapeo/features/messages/domain/entities/conversation_summary.dart';
import 'package:agapeo/features/messages/domain/entities/message.dart';
import 'package:agapeo/features/messages/domain/repositories/messages_repository.dart';

class FakeMessagesRepository implements MessagesRepository {
  FakeMessagesRepository({
    Result<String>? subscription,
    Result<List<ConversationSummary>>? conversations,
    Result<List<Message>>? messages,
    this.match = ConversationMatch.none,
  }) : subscription = subscription ?? const Ok('FREE'),
       conversations = conversations ?? const Ok([]),
       messages = messages ?? const Ok([]);

  Result<String> subscription;
  Result<List<ConversationSummary>> conversations;
  Result<List<Message>> messages;
  ConversationMatch match;
  var fetchConversationsCalls = 0;
  var sendTextCalls = 0;
  String? lastSendText;

  @override
  Future<Result<String>> fetchSubscriptionStatus() async => subscription;

  @override
  Future<Result<List<ConversationSummary>>> fetchConversations() async {
    fetchConversationsCalls++;
    return conversations;
  }

  @override
  Future<Result<ConversationSummary?>> fetchConversation(String id) async {
    switch (conversations) {
      case Ok(:final value):
        for (final c in value) {
          if (c.id == id) return Ok(c);
        }
        return const Ok(null);
      case Err(:final failure):
        return Err(failure);
    }
  }

  @override
  Future<Result<List<Message>>> fetchMessages(String conversationId) async =>
      messages;

  @override
  Future<Result<Message>> sendText({
    required String conversationId,
    required String text,
  }) async {
    sendTextCalls++;
    lastSendText = text;
    return Ok(
      Message(
        id: 'fake-sent',
        conversationId: conversationId,
        type: MessageType.text,
        createdAt: DateTime.now(),
        content: text,
        senderIsMe: true,
      ),
    );
  }

  @override
  Future<Result<void>> acceptInvitation(String conversationId) async =>
      const Ok(null);

  @override
  Future<Result<void>> declineInvitation(String conversationId) async =>
      const Ok(null);

  @override
  Future<Result<ConversationMatch>> fetchMatch(String conversationId) async =>
      Ok(match);

  @override
  Future<Result<ConversationMatch>> proposeMatch(
    String conversationId,
  ) async {
    match = const ConversationMatch(status: ConversationMatchStatus.pending);
    return Ok(match);
  }

  @override
  Future<Result<ConversationMatch>> acceptMatch(String conversationId) async {
    match = const ConversationMatch(status: ConversationMatchStatus.accepted);
    return Ok(match);
  }

  @override
  Future<Result<ConversationMatch>> declineMatch(
    String conversationId,
  ) async {
    match = ConversationMatch.none;
    return const Ok(ConversationMatch.none);
  }

  @override
  Future<Result<ConversationMatch>> cancelMatch(String conversationId) async {
    match = ConversationMatch.none;
    return const Ok(ConversationMatch.none);
  }

  @override
  Future<Result<void>> hideConversation(String conversationId) async =>
      const Ok(null);
}
