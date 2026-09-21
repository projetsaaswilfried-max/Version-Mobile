import '../../../../core/error/result.dart';
import '../entities/profile_hub.dart';
import '../repositories/profile_fields_repository.dart';

class GetProfileHub {
  const GetProfileHub(this._repo);

  final ProfileFieldsRepository _repo;

  Future<Result<ProfileHub>> call({required String fallbackEmail}) async {
    final result = await _repo.fetchFields();
    return switch (result) {
      Ok(:final value) => Ok(
        ProfileHub.fromFields(value, fallbackEmail: fallbackEmail),
      ),
      Err(:final failure) => Err(failure),
    };
  }
}
