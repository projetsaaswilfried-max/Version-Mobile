import 'package:equatable/equatable.dart';

import 'post.dart';

class FeedPage extends Equatable {
  const FeedPage({required this.items, required this.hasMore});

  final List<Post> items;
  final bool hasMore;

  @override
  List<Object?> get props => [items, hasMore];
}
