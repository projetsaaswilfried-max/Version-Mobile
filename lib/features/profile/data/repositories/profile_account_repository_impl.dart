import '../../../../core/error/map_data_exception.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/account_person.dart';
import '../../domain/entities/faith_details.dart';
import '../../domain/entities/more_info_details.dart';
import '../../domain/entities/privacy_settings.dart';
import '../../domain/entities/public_profile_preview.dart';
import '../../domain/entities/verification_info.dart';
import '../../domain/repositories/profile_account_repository.dart';
import '../datasources/profile_account_remote_datasource.dart';

class ProfileAccountRepositoryImpl implements ProfileAccountRepository {
  ProfileAccountRepositoryImpl(this._remote);

  final ProfileAccountRemoteDataSource _remote;

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<FaithDetails>> fetchFaith() => _guard(_remote.fetchFaith);

  @override
  Future<Result<void>> saveFaith(FaithDetails details) => _guard(() async {
    await _remote.saveFaith(details);
  });

  @override
  Future<Result<MoreInfoDetails>> fetchMoreInfo() =>
      _guard(_remote.fetchMoreInfo);

  @override
  Future<Result<void>> saveMoreInfo(MoreInfoDetails details) =>
      _guard(() async {
        await _remote.saveMoreInfo(details);
      });

  @override
  Future<Result<PrivacySettings>> fetchPrivacy() =>
      _guard(_remote.fetchPrivacy);

  @override
  Future<Result<void>> savePrivacy(PrivacySettings settings) =>
      _guard(() async {
        await _remote.savePrivacy(settings);
      });

  @override
  Future<Result<List<AccountPerson>>> fetchFavorites() =>
      _guard(_remote.fetchFavorites);

  @override
  Future<Result<void>> removeFavorite(String profileId) => _guard(() async {
    await _remote.removeFavorite(profileId);
  });

  @override
  Future<Result<InterestedPeople>> fetchInterested() =>
      _guard(_remote.fetchInterested);

  @override
  Future<Result<List<AccountPerson>>> fetchBlocked() =>
      _guard(_remote.fetchBlocked);

  @override
  Future<Result<void>> unblock(String profileId) => _guard(() async {
    await _remote.unblock(profileId);
  });

  @override
  Future<Result<VerificationInfo>> fetchVerification() =>
      _guard(_remote.fetchVerification);

  @override
  Future<Result<void>> submitVerification({
    required String selfiePath,
    bool forceNew = false,
  }) => _guard(() async {
    await _remote.submitVerification(
      selfiePath: selfiePath,
      forceNew: forceNew,
    );
  });

  @override
  Future<Result<void>> changeEmail(String email) => _guard(() async {
    await _remote.changeEmail(email);
  });

  @override
  Future<Result<String>> exportJson() => _guard(_remote.exportJson);

  @override
  Future<Result<void>> deleteAccount() => _guard(() async {
    await _remote.deleteAccount();
  });

  @override
  Future<Result<PublicProfilePreview>> fetchPublicPreview() =>
      _guard(_remote.fetchPublicPreview);

  @override
  Future<Result<void>> addVerifiedPhoto({
    required String photoPath,
    required String selfiePath,
  }) => _guard(() async {
    await _remote.addVerifiedPhoto(
      photoPath: photoPath,
      selfiePath: selfiePath,
    );
  });
}
