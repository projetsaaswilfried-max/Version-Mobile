import 'package:equatable/equatable.dart';

class PostComment extends Equatable {
  const PostComment({
    required this.id,
    required this.body,
    required this.authorName,
    this.authorAvatarUrl,
    bool isVerified = false,
    this.parentId,
    this.createdAt,
  }) : _isVerified = isVerified;

  final String id;
  final String body;
  final String authorName;
  final String? authorAvatarUrl;
  final bool? _isVerified;
  final String? parentId;
  final DateTime? createdAt;

  bool get isVerified => _isVerified == true;

  bool get isReply => parentId != null;

  @override
  List<Object?> get props => [
    id,
    body,
    authorName,
    authorAvatarUrl,
    isVerified,
    parentId,
    createdAt,
  ];
}
