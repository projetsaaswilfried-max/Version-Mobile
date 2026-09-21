import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/post.dart';
import '../personal/personal_post_rules.dart';
import '../repositories/feed_repository.dart';

class UpdatePersonalPost {
  const UpdatePersonalPost(this._repo);

  final FeedRepository _repo;

  Future<Result<Post>> call({required String postId, required String body}) {
    final trimmed = body.trim();
    if (trimmed.length > PersonalPostRules.maxChars) {
      return Future.value(
        const Err(ValidationFailure('600 caractères maximum.')),
      );
    }
    // Le média n'est pas éditable ici : un body vide reste valide si le post
    // avait déjà un média (contrairement à la création).
    return _repo.updatePersonalPost(postId: postId, body: trimmed);
  }
}
