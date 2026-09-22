import 'package:agapeo/core/error/exceptions.dart';
import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/profile/data/datasources/profile_fields_remote_datasource.dart';
import 'package:agapeo/features/profile/data/repositories/profile_fields_repository_impl.dart';
import 'package:agapeo/features/profile/domain/entities/profile_fields_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeProfileFieldsRemoteDataSource
    implements ProfileFieldsRemoteDataSource {
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
  })?
  raw;
  Exception? toThrow;

  @override
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
  fetchFieldsRaw() async {
    if (toThrow != null) throw toThrow!;
    return raw!;
  }
}

void main() {
  late FakeProfileFieldsRemoteDataSource datasource;
  late ProfileFieldsRepositoryImpl repository;

  setUp(() {
    datasource = FakeProfileFieldsRemoteDataSource();
    repository = ProfileFieldsRepositoryImpl(datasource);
  });

  test('maps name, verification and photo url onto the snapshot', () async {
    datasource.raw = (
      gender: 'FEMALE',
      birthDate: '1992-03-04',
      country: 'France',
      denomination: 'Pentecostal',
      whyMarriage: 'Alliance',
      maritalStatus: 'SINGLE_NO_CHILDREN',
      hobbies: const ['Randonnée'],
      hasPrimaryPhoto: true,
      firstName: ' Léa ',
      lastName: 'Martin',
      photoVerificationStatus: 'VERIFIED',
      primaryPhotoUrl: 'https://cdn/p.jpg',
    );

    final result = await repository.fetchFields();
    final snapshot = (result as Ok<ProfileFieldsSnapshot>).value;
    expect(snapshot.firstName, 'Léa');
    expect(snapshot.lastName, 'Martin');
    expect(snapshot.photoVerificationStatus, 'VERIFIED');
    expect(snapshot.primaryPhotoUrl, 'https://cdn/p.jpg');
    expect(snapshot.hasPrimaryPhoto, isTrue);
  });

  test('keeps photo flag when primary url is missing', () async {
    datasource.raw = (
      gender: null,
      birthDate: null,
      country: null,
      denomination: null,
      whyMarriage: null,
      maritalStatus: null,
      hobbies: const [],
      hasPrimaryPhoto: true,
      firstName: null,
      lastName: null,
      photoVerificationStatus: null,
      primaryPhotoUrl: null,
    );

    final result = await repository.fetchFields();
    final snapshot = (result as Ok<ProfileFieldsSnapshot>).value;
    expect(snapshot.hasPrimaryPhoto, isTrue);
    expect(snapshot.primaryPhotoUrl, isNull);
  });

  test('maps NetworkException to Err NetworkFailure', () async {
    datasource.toThrow = const NetworkException('offline');

    final result = await repository.fetchFields();

    expect(result, isA<Err<ProfileFieldsSnapshot>>());
    final failure = (result as Err<ProfileFieldsSnapshot>).failure;
    expect(failure, isA<NetworkFailure>());
    expect(failure.message, 'offline');
  });
}
