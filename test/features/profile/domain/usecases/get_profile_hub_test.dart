import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/profile/domain/entities/profile_fields_snapshot.dart';
import 'package:agapeo/features/profile/domain/entities/profile_hub.dart';
import 'package:agapeo/features/profile/domain/repositories/profile_fields_repository.dart';
import 'package:agapeo/features/profile/domain/usecases/get_profile_hub.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repo implements ProfileFieldsRepository {
  _Repo(this.result);

  final Result<ProfileFieldsSnapshot> result;

  @override
  Future<Result<ProfileFieldsSnapshot>> fetchFields() async => result;
}

void main() {
  test('maps Ok snapshot to ProfileHub', () async {
    final usecase = GetProfileHub(
      _Repo(
        Ok(
          const ProfileFieldsSnapshot(
            hasGender: true,
            hasBirthDate: true,
            hasCountry: true,
            hasPrimaryPhoto: false,
            hasFaithConfession: true,
            hasWhyMarriage: true,
            firstName: 'Paul',
            lastName: 'N.',
            photoVerificationStatus: 'VERIFIED',
          ),
        ),
      ),
    );
    final result = await usecase(fallbackEmail: 'paul@agapeo.love');
    final hub = (result as Ok<ProfileHub>).value;
    expect(hub.displayName, 'Paul N.');
    expect(hub.isVerified, isTrue);
  });

  test('forwards Err', () async {
    const failure = NetworkFailure('offline');
    final usecase = GetProfileHub(_Repo(const Err(failure)));
    final result = await usecase(fallbackEmail: 'a@b.c');
    expect((result as Err<ProfileHub>).failure, failure);
  });
}
