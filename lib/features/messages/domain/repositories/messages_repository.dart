import '../../../../core/error/result.dart';
import '../entities/conversation_match.dart';
import '../entities/conversation_summary.dart';
import '../entities/message.dart';

abstract class MessagesRepository {
  Future<Result<String>> fetchSubscriptionStatus();
  Future<Result<List<ConversationSummary>>> fetchConversations();
  Future<Result<ConversationSummary?>> fetchConversation(String id);
  Future<Result<List<Message>>> fetchMessages(String conversationId);
  Future<Result<Message>> sendText({
    required String conversationId,
    required String text,
  });
  Future<Result<Message>> sendImage({
    required String conversationId,
    required String localPath,
  });
  Future<Result<Message>> sendVoice({
    required String conversationId,
    required String localPath,
    required int durationSeconds,
  });
  Future<Result<void>> deleteMessage(String messageId);
  Future<Result<void>> markConversationRead(String conversationId);
  Future<Result<void>> acceptInvitation(String conversationId);
  Future<Result<void>> declineInvitation(String conversationId);
  Future<Result<ConversationMatch>> fetchMatch(String conversationId);
  Future<Result<ConversationMatch>> proposeMatch(
    String conversationId, {
    required String recipientId,
  });
  Future<Result<ConversationMatch>> acceptMatch(String conversationId);
  Future<Result<ConversationMatch>> declineMatch(String conversationId);
  Future<Result<ConversationMatch>> cancelMatch(String conversationId);
  Future<Result<void>> hideConversation(String conversationId);
}
