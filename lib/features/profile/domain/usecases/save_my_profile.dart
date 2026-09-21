import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/my_profile.dart';
import '../repositories/my_profile_repository.dart';

class SaveMyProfile {
  const SaveMyProfile(this._repo);

  final MyProfileRepository _repo;

  static const maxBioLength = 600;

  Future<Result<void>> call(MyProfile profile) async {
    if (profile.bio.trim().length > maxBioLength) {
      return const Err(
        ValidationFailure('La bio ne peut pas dépasser 600 caractères.'),
      );
    }
    return _repo.save(profile, savePhotos: !profile.isVerified);
  }
}
