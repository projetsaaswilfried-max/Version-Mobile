import '../../../../core/error/result.dart';
import '../entities/account_person.dart';
import '../entities/faith_details.dart';
import '../entities/more_info_details.dart';
import '../entities/privacy_settings.dart';
import '../entities/public_profile_preview.dart';
import '../entities/verification_info.dart';

abstract class ProfileAccountRepository {
  Future<Result<FaithDetails>> fetchFaith();
  Future<Result<void>> saveFaith(FaithDetails details);

  Future<Result<MoreInfoDetails>> fetchMoreInfo();
  Future<Result<void>> saveMoreInfo(MoreInfoDetails details);

  Future<Result<PrivacySettings>> fetchPrivacy();
  Future<Result<void>> savePrivacy(PrivacySettings settings);

  Future<Result<List<AccountPerson>>> fetchFavorites();
  Future<Result<void>> removeFavorite(String profileId);

  Future<Result<InterestedPeople>> fetchInterested();

  Future<Result<List<AccountPerson>>> fetchBlocked();
  Future<Result<void>> unblock(String profileId);

  Future<Result<VerificationInfo>> fetchVerification();
  Future<Result<void>> submitVerification({
    required String selfiePath,
    bool forceNew = false,
  });

  Future<Result<void>> changeEmail(String email);
  Future<Result<String>> exportJson();
  Future<Result<void>> deleteAccount();

  Future<Result<PublicProfilePreview>> fetchPublicPreview();

  Future<Result<void>> addVerifiedPhoto({
    required String photoPath,
    required String selfiePath,
  });
}
