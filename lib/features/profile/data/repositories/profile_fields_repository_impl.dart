import '../../../../core/error/map_data_exception.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/profile_fields_snapshot.dart';
import '../../domain/repositories/profile_fields_repository.dart';
import '../datasources/profile_fields_remote_datasource.dart';

class ProfileFieldsRepositoryImpl implements ProfileFieldsRepository {
  ProfileFieldsRepositoryImpl(this._remote);

  final ProfileFieldsRemoteDataSource _remote;

  @override
  Future<Result<ProfileFieldsSnapshot>> fetchFields() async {
    try {
      final raw = await _remote.fetchFieldsRaw();
      final gender = raw.gender?.trim();
      final birth = raw.birthDate?.trim();
      final country = raw.country?.trim();
      final denomination = raw.denomination?.trim();
      final why = raw.whyMarriage?.trim();
      final maritalStatus = raw.maritalStatus?.trim();
      return Ok(
        ProfileFieldsSnapshot(
          hasGender: gender != null && gender.isNotEmpty,
          hasBirthDate: birth != null && birth.isNotEmpty,
          hasCountry: country != null && country.isNotEmpty,
          hasPrimaryPhoto: raw.hasPrimaryPhoto,
          hasFaithConfession: denomination != null && denomination.isNotEmpty,
          hasWhyMarriage: why != null && why.isNotEmpty,
          hasMaritalStatus: maritalStatus != null && maritalStatus.isNotEmpty,
          hasHobbies: raw.hobbies.isNotEmpty,
          genderDb: gender,
          birthDate: birth == null ? null : DateTime.tryParse(birth),
          country: country,
          firstName: _nonEmpty(raw.firstName),
          lastName: _nonEmpty(raw.lastName),
          photoVerificationStatus: _nonEmpty(raw.photoVerificationStatus),
          primaryPhotoUrl: _nonEmpty(raw.primaryPhotoUrl),
        ),
      );
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
