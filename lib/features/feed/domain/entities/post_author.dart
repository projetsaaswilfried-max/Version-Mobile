import 'package:equatable/equatable.dart';

class PostAuthor extends Equatable {
  const PostAuthor({
    this.id,
    required this.displayName,
    this.avatarUrl,
    this.isVerified = false,
  });

  final String? id;
  final String displayName;
  final String? avatarUrl;
  final bool isVerified;

  @override
  List<Object?> get props => [id, displayName, avatarUrl, isVerified];
}
