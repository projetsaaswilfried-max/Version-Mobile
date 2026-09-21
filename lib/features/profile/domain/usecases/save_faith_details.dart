import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/faith_details.dart';
import '../repositories/profile_account_repository.dart';

class SaveFaithDetails {
  const SaveFaithDetails(this._repo);

  final ProfileAccountRepository _repo;

  Future<Result<void>> call(FaithDetails details) async {
    if (details.verse.trim().length > FaithDetails.maxVerse) {
      return const Err(
        ValidationFailure('Le verset ne peut pas dépasser 200 caractères.'),
      );
    }
    if (details.testimony.trim().length > FaithDetails.maxTestimony) {
      return const Err(
        ValidationFailure('Le témoignage ne peut pas dépasser 600 caractères.'),
      );
    }
    if (details.godWork.trim().length > FaithDetails.maxGodWork) {
      return const Err(
        ValidationFailure('Ce champ ne peut pas dépasser 600 caractères.'),
      );
    }
    if (details.whyMarriage.trim().length > FaithDetails.maxWhyMarriage) {
      return const Err(
        ValidationFailure('Ce champ ne peut pas dépasser 1000 caractères.'),
      );
    }
    return _repo.saveFaith(details);
  }
}
