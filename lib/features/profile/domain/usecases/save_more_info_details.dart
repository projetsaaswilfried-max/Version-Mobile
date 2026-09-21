import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/more_info_details.dart';
import '../repositories/profile_account_repository.dart';

class SaveMoreInfoDetails {
  const SaveMoreInfoDetails(this._repo);

  final ProfileAccountRepository _repo;

  Future<Result<void>> call(MoreInfoDetails details) async {
    if (details.qualities.length > MoreInfoDetails.maxQualities) {
      return const Err(ValidationFailure('10 qualités maximum.'));
    }
    if (details.passions.length > MoreInfoDetails.maxPassions) {
      return const Err(ValidationFailure('12 passions maximum.'));
    }
    if (details.values.length > MoreInfoDetails.maxValues) {
      return const Err(ValidationFailure('12 valeurs maximum.'));
    }
    if (details.familyVision.trim().length > MoreInfoDetails.maxFamilyVision) {
      return const Err(
        ValidationFailure(
          'La vision familiale ne peut pas dépasser 1000 caractères.',
        ),
      );
    }
    return _repo.saveMoreInfo(details);
  }
}
