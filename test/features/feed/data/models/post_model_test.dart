import 'package:agapeo/features/feed/data/models/post_model.dart';
import 'package:agapeo/features/feed/domain/entities/post_category.dart';
import 'package:agapeo/features/feed/domain/entities/post_media_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns null for PERSONAL posts', () {
    expect(
      PostModel.fromJson({'id': '1', 'post_type': 'PERSONAL', 'content': 'x'}),
      isNull,
    );
  });

  test('parses PERSONAL when includePersonal is true', () {
    final post = PostModel.fromJson({
      'id': 'p-perso',
      'post_type': 'PERSONAL',
      'content': 'Mon jour',
    }, includePersonal: true);
    expect(post, isNotNull);
    expect(post!.id, 'p-perso');
    expect(post.body, 'Mon jour');
  });

  test('parses official text post with counters and pin', () {
    final post = PostModel.fromJson({
      'id': 'p1',
      'post_type': 'OFFICIAL',
      'category': 'TEACHING',
      'content': 'Paix',
      'is_pinned': true,
      'likes_count': 3,
      'comments_count': 2,
      'shares_count': 1,
      'created_at': '2026-01-02T10:00:00Z',
    });
    expect(post, isNotNull);
    expect(post!.id, 'p1');
    expect(post.category, PostCategory.teaching);
    expect(post.body, 'Paix');
    expect(post.mediaType, PostMediaType.textOnly);
    expect(post.isPinned, isTrue);
    expect(post.likeCount, 3);
    expect(post.commentCount, 2);
    expect(post.shareCount, 1);
    expect(post.author.displayName, 'Équipe Agapeo');
    expect(post.author.isVerified, isFalse);
  });

  test('parses IMAGE from post_media', () {
    final post = PostModel.fromJson({
      'id': 'p2',
      'post_type': 'OFFICIAL',
      'post_media': [
        {'media_type': 'IMAGE', 'url': 'https://cdn.example/a.jpg'},
      ],
    });
    expect(post!.mediaType, PostMediaType.image);
    expect(post.imageUrl, 'https://cdn.example/a.jpg');
  });

  test('parses GALLERY first image and count', () {
    final post = PostModel.fromJson({
      'id': 'p3',
      'post_type': 'OFFICIAL',
      'post_media': [
        {'type': 'GALLERY', 'url': 'https://cdn.example/1.jpg'},
        {'type': 'GALLERY', 'url': 'https://cdn.example/2.jpg'},
        {'type': 'GALLERY', 'storage_path': 'https://cdn.example/3.jpg'},
      ],
    });
    expect(post!.mediaType, PostMediaType.gallery);
    expect(post.imageUrl, 'https://cdn.example/1.jpg');
    expect(post.galleryCount, 3);
    expect(post.mediaUrls, [
      'https://cdn.example/1.jpg',
      'https://cdn.example/2.jpg',
      'https://cdn.example/3.jpg',
    ]);
  });

  test('parses VIDEO thumbnail', () {
    final post = PostModel.fromJson({
      'id': 'p4',
      'post_type': 'OFFICIAL',
      'post_media': [
        {
          'media_type': 'VIDEO',
          'thumbnail_url': 'https://cdn.example/thumb.jpg',
          'url': 'https://cdn.example/v.mp4',
        },
      ],
    });
    expect(post!.mediaType, PostMediaType.video);
    expect(post.thumbnailUrl, 'https://cdn.example/thumb.jpg');
    expect(post.imageUrl, 'https://cdn.example/v.mp4');
  });

  test(
    'native VIDEO post with no post_media row reads posts.video_url',
    () {
      // Reproduit le post réel qui ne se lisait pas sur mobile (export
      // Supabase 2026-09-20) : posts.video_url porte le fichier, aucune
      // ligne post_media n'existe pour ce post.
      final post = PostModel.fromJson({
        'id': '07f28e5c-0051-4af2-864b-30cd7e6aca0e',
        'post_type': 'OFFICIAL',
        'media_type': 'VIDEO',
        'video_url':
            'https://cfmrykzqxcjhpktuxopu.supabase.co/storage/v1/object/public/post-media/0c5ee3b3-7bb9-4d75-9bae-428097ca4121/official-1789939392685/1789939392686-IMG_5768.MOV',
        'video_thumbnail':
            'https://cfmrykzqxcjhpktuxopu.supabase.co/storage/v1/object/public/post-media/0c5ee3b3-7bb9-4d75-9bae-428097ca4121/official-1789939777055-thumb/1789939777057-official-1789939777054-thumbnail.jpg',
      });
      expect(post!.mediaType, PostMediaType.video);
      expect(
        post.imageUrl,
        'https://cfmrykzqxcjhpktuxopu.supabase.co/storage/v1/object/public/post-media/0c5ee3b3-7bb9-4d75-9bae-428097ca4121/official-1789939392685/1789939392686-IMG_5768.MOV',
      );
      expect(
        post.thumbnailUrl,
        'https://cfmrykzqxcjhpktuxopu.supabase.co/storage/v1/object/public/post-media/0c5ee3b3-7bb9-4d75-9bae-428097ca4121/official-1789939777055-thumb/1789939777057-official-1789939777054-thumbnail.jpg',
      );
      expect(post.youtubeUrl, isNull);
    },
  );

  test(
    'VIDEO with a thumbnail row in post_media never picks the image as playable url',
    () {
      // Bug remonté en test manuel : deux lignes post_media (vidéo + vignette
      // générée) sans ordre garanti - la vignette arrivait en premier et
      // était lue par ExoPlayer comme si c'était la vidéo.
      final post = PostModel.fromJson({
        'id': 'p4b',
        'post_type': 'OFFICIAL',
        'media_type': 'VIDEO',
        'post_media': [
          {
            'media_type': 'IMAGE',
            'url':
                'https://cdn.example/official-1-thumb/1-official-1-thumbnail.jpg',
          },
          {'media_type': 'VIDEO', 'url': 'https://cdn.example/official-1.mp4'},
        ],
      });
      expect(post!.mediaType, PostMediaType.video);
      expect(post.imageUrl, 'https://cdn.example/official-1.mp4');
      expect(
        post.thumbnailUrl,
        'https://cdn.example/official-1-thumb/1-official-1-thumbnail.jpg',
      );
    },
  );

  test('parses YOUTUBE url, thumbnail and watch link', () {
    final post = PostModel.fromJson({
      'id': 'p5',
      'post_type': 'OFFICIAL',
      'post_media': [
        {
          'media_type': 'YOUTUBE',
          'youtube_url': 'https://www.youtube.com/watch?v=abcdefghijk',
        },
      ],
    });
    expect(post!.mediaType, PostMediaType.youtube);
    expect(post.youtubeUrl, 'https://www.youtube.com/watch?v=abcdefghijk');
    expect(
      post.thumbnailUrl,
      'https://img.youtube.com/vi/abcdefghijk/hqdefault.jpg',
    );
  });

  test('parses YOUTUBE from posts.video_url like the web feed', () {
    final post = PostModel.fromJson({
      'id': 'p5b',
      'post_type': 'OFFICIAL',
      'media_type': 'YOUTUBE',
      'video_url': 'oiJPxqTSkWE',
      'video_thumbnail': 'https://img.youtube.com/vi/oiJPxqTSkWE/hqdefault.jpg',
      'content': 'Un enseignement',
    });
    expect(post!.mediaType, PostMediaType.youtube);
    expect(post.youtubeUrl, 'https://www.youtube.com/watch?v=oiJPxqTSkWE');
    expect(
      post.thumbnailUrl,
      'https://img.youtube.com/vi/oiJPxqTSkWE/hqdefault.jpg',
    );
  });

  test('parses YOUTUBE when post_media maps are untyped', () {
    final post = PostModel.fromJson({
      'id': 'p5c',
      'post_type': 'OFFICIAL',
      'post_media': [
        <dynamic, dynamic>{
          'media_type': 'YOUTUBE',
          'url': 'https://www.youtube.com/watch?v=abcdefghijk',
        },
      ],
    });
    expect(post!.mediaType, PostMediaType.youtube);
    expect(post.youtubeUrl, 'https://www.youtube.com/watch?v=abcdefghijk');
  });

  test('parses QUOTE_CARD', () {
    final post = PostModel.fromJson({
      'id': 'p6',
      'post_type': 'OFFICIAL',
      'category': 'QUOTE',
      'content': 'Aimez-vous les uns les autres',
      'quote_author': 'Jean 13.34',
      'media_type': 'QUOTE_CARD',
    });
    expect(post!.mediaType, PostMediaType.quoteCard);
    expect(post.body, 'Aimez-vous les uns les autres');
    expect(post.quoteAttribution, 'Jean 13.34');
  });

  test('reads author embed, verification and alternative count keys', () {
    final post = PostModel.fromJson({
      'id': 'p7',
      'post_type': 'OFFICIAL',
      'body': 'Hi',
      'pinned': true,
      'like_count': 9,
      'comment_count': 4,
      'share_count': 2,
      'author': {
        'first_name': 'Marie',
        'last_name': 'A.',
        'photo_verification_status': 'VERIFIED',
        'profile_photos': [
          {'storage_path': 'https://cdn.example/a.png', 'is_primary': true},
        ],
      },
    });
    expect(post!.author.displayName, 'Marie A.');
    expect(post.author.avatarUrl, 'https://cdn.example/a.png');
    expect(post.author.isVerified, isTrue);
    expect(post.isPinned, isTrue);
    expect(post.likeCount, 9);
  });

  test('keeps a real zero like count instead of a fallback column', () {
    final post = PostModel.fromJson({
      'id': 'p7b',
      'post_type': 'OFFICIAL',
      'content': 'x',
      'likes_count': 0,
      'like_count': 9,
    });
    expect(post!.likeCount, 0);
  });

  test('falls back to Agapeo when author embed has no name', () {
    final post = PostModel.fromJson({
      'id': 'p7c',
      'post_type': 'OFFICIAL',
      'content': 'x',
      'author': {'photo_verification_status': 'PENDING'},
    });
    expect(post!.author.displayName, 'Équipe Agapeo');
    expect(post.author.isVerified, isFalse);
  });

  test('parses title and view count for the web card layout', () {
    final post = PostModel.fromJson({
      'id': 'p9',
      'post_type': 'OFFICIAL',
      'category': 'ADVICE',
      'title': 'Ne cours pas après le mariage (Ps Sthael DJATTI)',
      'content':
          '« Il y a un temps pour tout sous le soleil. » Et si ton célibat…',
      'views_count': 133,
    });
    expect(post!.title, 'Ne cours pas après le mariage (Ps Sthael DJATTI)');
    expect(post.body, contains('temps pour tout'));
    expect(post.viewCount, 133);
    expect(post.category, PostCategory.advice);
  });

  test('unknown media type falls back to text', () {
    final post = PostModel.fromJson({
      'id': 'p8',
      'post_type': 'OFFICIAL',
      'media_type': 'WEIRD',
      'content': 'x',
    });
    expect(post!.mediaType, PostMediaType.textOnly);
  });
}
