import 'package:equatable/equatable.dart';

import '../domain/entities/conversation_summary.dart';
import '../domain/filtering/filter_conversations.dart';

class MessagesState extends Equatable {
  const MessagesState({
    this.conversations = const [],
    this.searchQuery = '',
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
  });

  final List<ConversationSummary> conversations;
  final String searchQuery;
  final bool isInitialLoading;
  final bool isRefreshing;
  final String? errorMessage;

  List<ConversationSummary> get visibleConversations =>
      filterConversations(conversations, searchQuery);

  bool get isEmpty =>
      !isInitialLoading && errorMessage == null && visibleConversations.isEmpty;

  bool get hasNoConversations =>
      !isInitialLoading && errorMessage == null && conversations.isEmpty;

  MessagesState copyWith({
    List<ConversationSummary>? conversations,
    String? searchQuery,
    bool? isInitialLoading,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MessagesState(
      conversations: conversations ?? this.conversations,
      searchQuery: searchQuery ?? this.searchQuery,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    conversations,
    searchQuery,
    isInitialLoading,
    isRefreshing,
    errorMessage,
  ];
}
