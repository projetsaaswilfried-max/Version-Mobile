import '../../../../core/error/result.dart';
import '../entities/personal_post_media.dart';
import '../entities/post.dart';
import '../personal/personal_post_rules.dart';
import '../repositories/feed_repository.dart';

class CreatePersonalPost {
  const CreatePersonalPost(this._repo);

  final FeedRepository _repo;

  Future<Result<Post>> call({required String body, PersonalPostMedia? media}) {
    final trimmed = body.trim();
    final error = PersonalPostRules.validate(body: trimmed, media: media);
    if (error != null) return Future.value(Err(error));
    return _repo.createPersonalPost(body: trimmed, media: media);
  }
}
