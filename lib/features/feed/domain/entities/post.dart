import 'package:equatable/equatable.dart';

import 'post_author.dart';
import 'post_category.dart';
import 'post_media_type.dart';

class Post extends Equatable {
  const Post({
    required this.id,
    required this.author,
    this.category,
    this.title,
    required this.body,
    required this.mediaType,
    this.imageUrl,
    this.thumbnailUrl,
    this.mediaUrls = const [],
    this.galleryCount = 1,
    this.quoteAttribution,
    this.youtubeUrl,
    required this.isPinned,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    this.viewCount = 0,
    this.likedByMe = false,
    this.bookmarkedByMe = false,
    this.createdAt,
  });

  final String id;
  final PostAuthor author;
  final PostCategory? category;
  final String? title;
  final String body;
  final PostMediaType mediaType;
  final String? imageUrl;
  final String? thumbnailUrl;
  final List<String> mediaUrls;
  final int galleryCount;
  final String? quoteAttribution;
  final String? youtubeUrl;
  final bool isPinned;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final int viewCount;
  final bool likedByMe;
  final bool bookmarkedByMe;
  final DateTime? createdAt;

  Post copyWith({
    String? id,
    PostAuthor? author,
    PostCategory? category,
    String? title,
    String? body,
    PostMediaType? mediaType,
    String? imageUrl,
    String? thumbnailUrl,
    List<String>? mediaUrls,
    int? galleryCount,
    String? quoteAttribution,
    String? youtubeUrl,
    bool? isPinned,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    int? viewCount,
    bool? likedByMe,
    bool? bookmarkedByMe,
    DateTime? createdAt,
  }) {
    return Post(
      id: id ?? this.id,
      author: author ?? this.author,
      category: category ?? this.category,
      title: title ?? this.title,
      body: body ?? this.body,
      mediaType: mediaType ?? this.mediaType,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      galleryCount: galleryCount ?? this.galleryCount,
      quoteAttribution: quoteAttribution ?? this.quoteAttribution,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      isPinned: isPinned ?? this.isPinned,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      viewCount: viewCount ?? this.viewCount,
      likedByMe: likedByMe ?? this.likedByMe,
      bookmarkedByMe: bookmarkedByMe ?? this.bookmarkedByMe,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    author,
    category,
    title,
    body,
    mediaType,
    imageUrl,
    thumbnailUrl,
    mediaUrls,
    galleryCount,
    quoteAttribution,
    youtubeUrl,
    isPinned,
    likeCount,
    commentCount,
    shareCount,
    viewCount,
    likedByMe,
    bookmarkedByMe,
    createdAt,
  ];
}
