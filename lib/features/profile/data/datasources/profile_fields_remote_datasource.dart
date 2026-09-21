abstract class ProfileFieldsRemoteDataSource {
  Future<
    ({
      String? gender,
      String? birthDate,
      String? country,
      String? denomination,
      String? whyMarriage,
      bool hasPrimaryPhoto,
      String? firstName,
      String? lastName,
      String? photoVerificationStatus,
      String? primaryPhotoUrl,
    })
  >
  fetchFieldsRaw();
}
