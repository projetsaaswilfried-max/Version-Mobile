import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/profile/domain/entities/account_person.dart';
import 'package:agapeo/features/profile/domain/entities/faith_details.dart';
import 'package:agapeo/features/profile/domain/entities/more_info_details.dart';
import 'package:agapeo/features/profile/domain/entities/privacy_settings.dart';
import 'package:agapeo/features/profile/domain/entities/public_profile_preview.dart';
import 'package:agapeo/features/profile/domain/entities/verification_info.dart';
import 'package:agapeo/features/profile/domain/repositories/profile_account_repository.dart';

class FakeProfileAccountRepository implements ProfileAccountRepository {
  FakeProfileAccountRepository({
    this.faith = const FaithDetails(
      denomination: 'Évangélique',
      whyMarriage: 'Alliance',
      testimony: 'Hello',
      testimonyAvailable: true,
      verseAvailable: true,
      verse: 'Jean 3:16',
    ),
    this.moreInfo = const MoreInfoDetails(
      values: ['Foi'],
      valuesAvailable: true,
      passions: ['Course'],
      passionsAvailable: true,
    ),
    this.privacy = const PrivacySettings(
      switches: [
        PrivacySwitch(
          id: 'show_online_status',
          label: 'Statut en ligne',
          value: true,
        ),
      ],
    ),
    this.favorites = const [
      AccountPerson(id: '2', displayName: 'Marc Dupont', city: 'Lyon'),
    ],
    this.interested = const InterestedPeople(
      count: 1,
      revealIdentities: true,
      people: [AccountPerson(id: '3', displayName: 'Noah Bernard')],
    ),
    this.blocked = const [AccountPerson(id: '4', displayName: 'Compte bloqué')],
    this.verification = const VerificationInfo(
      status: 'UNVERIFIED',
      isComplete: true,
      email: 'lea@agapeo.love',
    ),
    this.publicPreview = const PublicProfilePreview(
      id: 'user-lea',
      displayName: 'Léa Martin',
      age: 28,
      city: 'Paris',
      country: 'France',
      gender: 'FEMALE',
      profession: 'Designer',
      bio: 'Hello',
      heightCm: 168,
      denomination: 'Évangélique',
      spiritualEngagement: 'Pratique',
      whyMarriage: 'Pour bâtir une famille',
      verse: 'Jean 3:16',
      testimony: 'Mon parcours',
      values: ['Respect', 'Fidélité'],
      passions: ['Lecture', 'Marche'],
      qualities: ['Bienveillante'],
    ),
    this.exportJsonValue = '{"ok":true}',
    this.saveResult = const Ok(null),
  });

  FaithDetails faith;
  MoreInfoDetails moreInfo;
  PrivacySettings privacy;
  List<AccountPerson> favorites;
  InterestedPeople interested;
  List<AccountPerson> blocked;
  VerificationInfo verification;
  PublicProfilePreview publicPreview;
  String exportJsonValue;
  Result<void> saveResult;
  String? lastRemovedFavorite;
  String? lastUnblocked;
  String? lastEmail;
  String? lastSelfiePath;
  bool deleteCalled = false;

  @override
  Future<Result<FaithDetails>> fetchFaith() async => Ok(faith);

  @override
  Future<Result<void>> saveFaith(FaithDetails details) async {
    faith = details;
    return saveResult;
  }

  @override
  Future<Result<MoreInfoDetails>> fetchMoreInfo() async => Ok(moreInfo);

  @override
  Future<Result<void>> saveMoreInfo(MoreInfoDetails details) async {
    moreInfo = details;
    return saveResult;
  }

  @override
  Future<Result<PrivacySettings>> fetchPrivacy() async => Ok(privacy);

  @override
  Future<Result<void>> savePrivacy(PrivacySettings settings) async {
    privacy = settings;
    return saveResult;
  }

  @override
  Future<Result<List<AccountPerson>>> fetchFavorites() async => Ok(favorites);

  @override
  Future<Result<void>> removeFavorite(String profileId) async {
    lastRemovedFavorite = profileId;
    favorites = favorites.where((p) => p.id != profileId).toList();
    return saveResult;
  }

  @override
  Future<Result<InterestedPeople>> fetchInterested() async => Ok(interested);

  @override
  Future<Result<List<AccountPerson>>> fetchBlocked() async => Ok(blocked);

  @override
  Future<Result<void>> unblock(String profileId) async {
    lastUnblocked = profileId;
    blocked = blocked.where((p) => p.id != profileId).toList();
    return saveResult;
  }

  @override
  Future<Result<VerificationInfo>> fetchVerification() async =>
      Ok(verification);

  @override
  Future<Result<void>> submitVerification({
    required String selfiePath,
    bool forceNew = false,
  }) async {
    lastSelfiePath = selfiePath;
    return saveResult;
  }

  @override
  Future<Result<void>> changeEmail(String email) async {
    lastEmail = email;
    return saveResult;
  }

  @override
  Future<Result<String>> exportJson() async => Ok(exportJsonValue);

  @override
  Future<Result<void>> deleteAccount() async {
    deleteCalled = true;
    return saveResult;
  }

  @override
  Future<Result<PublicProfilePreview>> fetchPublicPreview() async =>
      Ok(publicPreview);

  @override
  Future<Result<void>> addVerifiedPhoto({
    required String photoPath,
    required String selfiePath,
  }) async => saveResult;
}
