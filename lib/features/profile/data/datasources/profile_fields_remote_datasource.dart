abstract class ProfileFieldsRemoteDataSource {
  Future<
    ({
      String? gender,
      String? birthDate,
      String? country,
      String? denomination,
      String? whyMarriage,
      String? maritalStatus,
      List<String> hobbies,
      bool hasPrimaryPhoto,
      String? firstName,
      String? lastName,
      String? photoVerificationStatus,
      String? primaryPhotoUrl,
    })
  >
  fetchFieldsRaw();
}
