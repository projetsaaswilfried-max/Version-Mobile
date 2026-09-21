import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/di/providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/datasources/supabase_messages_datasource.dart';
import '../data/repositories/messages_repository_impl.dart';
import '../data/repositories/seeded_messages_repository.dart';
import '../domain/entities/conversation_match.dart';
import '../domain/entities/conversation_summary.dart';
import '../domain/entities/message.dart';
import '../domain/repositories/messages_repository.dart';
import '../domain/usecases/accept_conversation_invitation.dart';
import '../domain/usecases/decline_conversation_invitation.dart';
import '../domain/usecases/get_conversation.dart';
import '../domain/usecases/get_conversations.dart';
import '../domain/usecases/get_messages.dart';
import '../domain/usecases/send_text_message.dart';

/// `true` = seed local (tests / UI hors backend). Prod/dev : `false` (slice A).
const bool kUseFakeMessagesConversations = false;

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  if (kUseFakeMessagesConversations) {
    return SeededMessagesRepository();
  }
  final env = AppEnvironment.current;
  if (env.supabaseUrl.isEmpty || env.supabaseAnonKey.isEmpty) {
    return const UnconfiguredMessagesRepository();
  }
  return MessagesRepositoryImpl(
    SupabaseMessagesDataSource(ref.watch(supabaseClientProvider)),
  );
});

final getConversationsProvider = Provider(
  (ref) => GetConversations(ref.watch(messagesRepositoryProvider)),
);

final getConversationProvider = Provider(
  (ref) => GetConversation(ref.watch(messagesRepositoryProvider)),
);

final getMessagesProvider = Provider(
  (ref) => GetMessages(ref.watch(messagesRepositoryProvider)),
);

final sendTextMessageProvider = Provider(
  (ref) => SendTextMessage(ref.watch(messagesRepositoryProvider)),
);

final acceptConversationInvitationProvider = Provider(
  (ref) => AcceptConversationInvitation(ref.watch(messagesRepositoryProvider)),
);

final declineConversationInvitationProvider = Provider(
  (ref) => DeclineConversationInvitation(ref.watch(messagesRepositoryProvider)),
);

class UnconfiguredMessagesRepository implements MessagesRepository {
  const UnconfiguredMessagesRepository();

  static const failure = ServerFailure(
    'Supabase non configuré : lance avec --dart-define=SUPABASE_URL=... '
    '--dart-define=SUPABASE_ANON_KEY=...',
  );

  @override
  Future<Result<String>> fetchSubscriptionStatus() async => const Err(failure);

  @override
  Future<Result<List<ConversationSummary>>> fetchConversations() async =>
      const Err(failure);

  @override
  Future<Result<ConversationSummary?>> fetchConversation(String id) async =>
      const Err(failure);

  @override
  Future<Result<List<Message>>> fetchMessages(String conversationId) async =>
      const Err(failure);

  @override
  Future<Result<Message>> sendText({
    required String conversationId,
    required String text,
  }) async => const Err(failure);

  @override
  Future<Result<void>> acceptInvitation(String conversationId) async =>
      const Err(failure);

  @override
  Future<Result<void>> declineInvitation(String conversationId) async =>
      const Err(failure);

  @override
  Future<Result<ConversationMatch>> fetchMatch(String conversationId) async =>
      const Err(failure);

  @override
  Future<Result<ConversationMatch>> proposeMatch(
    String conversationId,
  ) async => const Err(failure);

  @override
  Future<Result<ConversationMatch>> acceptMatch(String conversationId) async =>
      const Err(failure);

  @override
  Future<Result<ConversationMatch>> declineMatch(
    String conversationId,
  ) async => const Err(failure);

  @override
  Future<Result<ConversationMatch>> cancelMatch(String conversationId) async =>
      const Err(failure);

  @override
  Future<Result<void>> hideConversation(String conversationId) async =>
      const Err(failure);
}
