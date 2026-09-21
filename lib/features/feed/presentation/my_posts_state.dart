import 'package:equatable/equatable.dart';

import '../domain/entities/post.dart';

class MyPostsState extends Equatable {
  const MyPostsState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Post> items;
  final bool isLoading;
  final String? errorMessage;

  MyPostsState copyWith({
    List<Post>? items,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MyPostsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [items, isLoading, errorMessage];
}
