import '../../domain/entities/account_person.dart';
import '../../domain/entities/faith_details.dart';
import '../../domain/entities/more_info_details.dart';
import '../../domain/entities/privacy_settings.dart';
import '../../domain/entities/public_profile_preview.dart';
import '../../domain/entities/verification_info.dart';

abstract class ProfileAccountRemoteDataSource {
  Future<FaithDetails> fetchFaith();
  Future<void> saveFaith(FaithDetails details);
  Future<MoreInfoDetails> fetchMoreInfo();
  Future<void> saveMoreInfo(MoreInfoDetails details);
  Future<PrivacySettings> fetchPrivacy();
  Future<void> savePrivacy(PrivacySettings settings);
  Future<List<AccountPerson>> fetchFavorites();
  Future<void> removeFavorite(String profileId);
  Future<InterestedPeople> fetchInterested();
  Future<List<AccountPerson>> fetchBlocked();
  Future<void> unblock(String profileId);
  Future<VerificationInfo> fetchVerification();
  Future<void> submitVerification({
    required String selfiePath,
    bool forceNew = false,
  });
  Future<void> changeEmail(String email);
  Future<String> exportJson();
  Future<void> deleteAccount();
  Future<PublicProfilePreview> fetchPublicPreview();
  Future<void> addVerifiedPhoto({
    required String photoPath,
    required String selfiePath,
  });
}
