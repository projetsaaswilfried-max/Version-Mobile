import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/profile/domain/entities/my_profile.dart';
import 'package:agapeo/features/profile/domain/repositories/my_profile_repository.dart';
import 'package:agapeo/features/profile/domain/usecases/save_my_profile.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repo implements MyProfileRepository {
  bool? lastSavePhotos;

  @override
  Future<Result<MyProfile>> fetchMine() async => throw UnimplementedError();

  @override
  Future<Result<void>> save(
    MyProfile profile, {
    required bool savePhotos,
  }) async {
    lastSavePhotos = savePhotos;
    return const Ok(null);
  }

  @override
  Future<Result<void>> deletePhoto(String photoId) async =>
      throw UnimplementedError();
}

MyProfile profile({String bio = 'Hello', bool isVerified = false}) {
  return MyProfile(
    firstName: 'Léa',
    lastName: 'Martin',
    city: 'Paris',
    profession: 'Dev',
    bio: bio,
    isVerified: isVerified,
  );
}

void main() {
  test('rejects bio longer than 600 characters', () async {
    final repo = _Repo();
    final usecase = SaveMyProfile(repo);
    final result = await usecase(profile(bio: 'a' * 601));
    expect(result, isA<Err<void>>());
    expect((result as Err<void>).failure, isA<ValidationFailure>());
    expect(repo.lastSavePhotos, isNull);
  });

  test('does not save photos when verified', () async {
    final repo = _Repo();
    final usecase = SaveMyProfile(repo);
    final result = await usecase(profile(isVerified: true));
    expect(result, isA<Ok<void>>());
    expect(repo.lastSavePhotos, isFalse);
  });

  test('saves photos when not verified', () async {
    final repo = _Repo();
    final usecase = SaveMyProfile(repo);
    final result = await usecase(profile());
    expect(result, isA<Ok<void>>());
    expect(repo.lastSavePhotos, isTrue);
  });
}
