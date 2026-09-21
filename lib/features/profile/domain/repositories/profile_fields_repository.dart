import '../../../../core/error/result.dart';
import '../entities/profile_fields_snapshot.dart';

abstract class ProfileFieldsRepository {
  Future<Result<ProfileFieldsSnapshot>> fetchFields();
}
