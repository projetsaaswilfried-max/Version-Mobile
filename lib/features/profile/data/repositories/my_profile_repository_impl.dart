import '../../../../core/error/map_data_exception.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/my_profile.dart';
import '../../domain/repositories/my_profile_repository.dart';
import '../datasources/my_profile_remote_datasource.dart';

class MyProfileRepositoryImpl implements MyProfileRepository {
  MyProfileRepositoryImpl(this._remote);

  final MyProfileRemoteDataSource _remote;

  @override
  Future<Result<MyProfile>> fetchMine() async {
    try {
      final raw = await _remote.fetchRaw();
      return Ok(_map(raw));
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<void>> save(
    MyProfile profile, {
    required bool savePhotos,
  }) async {
    try {
      await _remote.save(profile, savePhotos: savePhotos);
      return const Ok(null);
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<void>> deletePhoto(String photoId) async {
    try {
      await _remote.deletePhoto(photoId);
      return const Ok(null);
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  MyProfile _map(MyProfileRaw raw) {
    return MyProfile(
      firstName: raw.firstName?.trim() ?? '',
      lastName: raw.lastName?.trim() ?? '',
      city: raw.city?.trim() ?? '',
      profession: raw.profession?.trim() ?? '',
      bio: raw.bio?.trim() ?? '',
      willingToRelocate: raw.willingToRelocate,
      relocateAvailable: raw.relocateAvailable,
      genderLabel: _genderLabel(raw.gender),
      birthDateLabel: _dateLabel(raw.birthDate),
      country: raw.country?.trim(),
      isVerified:
          (raw.photoVerificationStatus ?? '').toUpperCase() == 'VERIFIED',
      isPremium: raw.isPremium,
      photos: raw.photos,
      denomination: raw.denomination.trim(),
      whyMarriage: raw.whyMarriage.trim(),
      maritalStatusDb: raw.maritalStatusDb?.trim(),
    );
  }

  static String? _genderLabel(String? gender) {
    switch (gender?.toUpperCase()) {
      case 'FEMALE':
        return 'Femme';
      case 'MALE':
        return 'Homme';
      default:
        return gender?.trim();
    }
  }

  static String? _dateLabel(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    return '$day/$month/${parsed.year}';
  }
}
