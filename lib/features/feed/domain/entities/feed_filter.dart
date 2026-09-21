import 'package:equatable/equatable.dart';

import 'post_category.dart';

class FeedFilter extends Equatable {
  const FeedFilter.all() : category = null;

  const FeedFilter.byCategory(this.category);

  final PostCategory? category;

  bool get isAll => category == null;

  @override
  List<Object?> get props => [category];
}
