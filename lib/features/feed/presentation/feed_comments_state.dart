import 'package:equatable/equatable.dart';

import '../domain/entities/post_comment.dart';

class FeedCommentsState extends Equatable {
  const FeedCommentsState({
    this.comments = const [],
    this.isLoading = false,
    this.sending = false,
    this.errorMessage,
    this.replyTo,
  });

  final List<PostComment> comments;
  final bool isLoading;
  final bool sending;
  final String? errorMessage;
  final PostComment? replyTo;

  FeedCommentsState copyWith({
    List<PostComment>? comments,
    bool? isLoading,
    bool? sending,
    String? errorMessage,
    PostComment? replyTo,
    bool clearError = false,
    bool clearReply = false,
  }) {
    return FeedCommentsState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      sending: sending ?? this.sending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      replyTo: clearReply ? null : (replyTo ?? this.replyTo),
    );
  }

  @override
  List<Object?> get props => [
    comments,
    isLoading,
    sending,
    errorMessage,
    replyTo,
  ];
}
