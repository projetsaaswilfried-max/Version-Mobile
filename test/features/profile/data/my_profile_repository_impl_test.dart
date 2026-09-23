import 'package:agapeo/core/error/exceptions.dart';
import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/profile/data/datasources/my_profile_remote_datasource.dart';
import 'package:agapeo/features/profile/data/repositories/my_profile_repository_impl.dart';
import 'package:agapeo/features/profile/domain/entities/my_profile.dart';
import 'package:agapeo/features/profile/domain/entities/my_profile_photo.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeMyProfileRemoteDataSource implements MyProfileRemoteDataSource {
  MyProfileRaw? raw;
  Exception? toThrow;
  bool? lastSavePhotos;
  MyProfile? lastSaved;
  String? lastDeletedPhotoId;

  @override
  Future<MyProfileRaw> fetchRaw() async {
    if (toThrow != null) throw toThrow!;
    return raw!;
  }

  @override
  Future<void> save(MyProfile profile, {required bool savePhotos}) async {
    if (toThrow != null) throw toThrow!;
    lastSaved = profile;
    lastSavePhotos = savePhotos;
  }

  @override
  Future<void> deletePhoto(String photoId) async {
    if (toThrow != null) throw toThrow!;
    lastDeletedPhotoId = photoId;
  }
}

void main() {
  late FakeMyProfileRemoteDataSource remote;
  late MyProfileRepositoryImpl repo;

  setUp(() {
    remote = FakeMyProfileRemoteDataSource();
    repo = MyProfileRepositoryImpl(remote);
  });

  test('maps raw profile, labels and photos', () async {
    remote.raw = const MyProfileRaw(
      firstName: 'Léa',
      lastName: 'Martin',
      gender: 'FEMALE',
      birthDate: '1992-03-04',
      country: 'France',
      city: 'Paris',
      profession: 'Dev',
      bio: 'Hello',
      photoVerificationStatus: 'VERIFIED',
      willingToRelocate: true,
      relocateAvailable: true,
      photos: [MyProfilePhoto(id: 'p1', publicUrl: 'https://cdn/a.jpg')],
      denomination: 'Évangélique',
      whyMarriage: 'Alliance',
      maritalStatusDb: 'SINGLE_NO_CHILDREN',
    );

    final snapshot = ((await repo.fetchMine()) as Ok<MyProfile>).value;
    expect(snapshot.firstName, 'Léa');
    expect(snapshot.genderLabel, 'Femme');
    expect(snapshot.birthDateLabel, '04/03/1992');
    expect(snapshot.isVerified, isTrue);
    expect(snapshot.relocateAvailable, isTrue);
    expect(snapshot.willingToRelocate, isTrue);
    expect(snapshot.photos.single.id, 'p1');
    expect(snapshot.denomination, 'Évangélique');
    expect(snapshot.whyMarriage, 'Alliance');
    expect(snapshot.maritalStatusDb, 'SINGLE_NO_CHILDREN');
  });

  test('forwards savePhotos to remote', () async {
    const profile = MyProfile(
      firstName: 'Léa',
      lastName: 'Martin',
      city: '',
      profession: '',
      bio: '',
      isVerified: false,
    );
    await repo.save(profile, savePhotos: true);
    expect(remote.lastSavePhotos, isTrue);
    expect(remote.lastSaved, profile);
  });

  test('maps NetworkException to Err', () async {
    remote.toThrow = const NetworkException('offline');
    final result = await repo.fetchMine();
    expect((result as Err<MyProfile>).failure, isA<NetworkFailure>());
  });

  test('forwards deletePhoto to remote', () async {
    final result = await repo.deletePhoto('p1');
    expect(result, const Ok<void>(null));
    expect(remote.lastDeletedPhotoId, 'p1');
  });

  test('maps deletePhoto failure to Err', () async {
    remote.toThrow = const ServerException('boom');
    final result = await repo.deletePhoto('p1');
    expect((result as Err<void>).failure, isA<ServerFailure>());
  });
}
