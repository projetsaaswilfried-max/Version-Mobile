import 'package:agapeo/core/error/exceptions.dart';
import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/onboarding/data/datasources/onboarding_remote_datasource.dart';
import 'package:agapeo/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:agapeo/features/onboarding/domain/entities/onboarding_submit_payload.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRemote implements OnboardingRemoteDataSource {
  final calls = <String>[];
  Object? throwOnUpload;
  Object? throwOnUpdate;

  @override
  Future<void> updateProfileFields({
    required String genderDb,
    required DateTime birthDate,
    required String country,
    required String faithConfession,
    required String maritalStatusDb,
    required String whyMarriage,
    required bool onboardingCompleted,
  }) async {
    if (throwOnUpdate != null) throw throwOnUpdate!;
    calls.add('update:$onboardingCompleted');
  }

  @override
  Future<void> uploadPhoto({
    required String localPath,
    required int slot,
    required bool isPrimary,
  }) async {
    if (throwOnUpload != null) throw throwOnUpload!;
    calls.add('upload:$slot:$localPath:$isPrimary');
  }
}

void main() {
  final payload = OnboardingSubmitPayload(
    genderDb: 'FEMALE',
    birthDate: DateTime(1995, 1, 1),
    country: 'France',
    faithConfession: 'Évangélique',
    maritalStatusDb: 'SINGLE_NO_CHILDREN',
    whyMarriage: 'Alliance',
    photoPaths: const ['/tmp/a.jpg'],
  );

  test('submit uploads photo then updates profile', () async {
    final remote = _FakeRemote();
    final repo = OnboardingRepositoryImpl(remote);
    final r = await repo.submit(payload);
    expect(r, isA<Ok<void>>());
    expect(remote.calls, ['upload:0:/tmp/a.jpg:true', 'update:true']);
  });

  test('submit uploads every photo slot', () async {
    final remote = _FakeRemote();
    final repo = OnboardingRepositoryImpl(remote);
    final r = await repo.submit(
      OnboardingSubmitPayload(
        genderDb: 'FEMALE',
        birthDate: DateTime(1995, 1, 1),
        country: 'France',
        faithConfession: 'Évangélique',
        maritalStatusDb: 'SINGLE_NO_CHILDREN',
        whyMarriage: 'Alliance',
        photoPaths: const ['/tmp/a.jpg', '/tmp/b.jpg'],
      ),
    );
    expect(r, isA<Ok<void>>());
    expect(remote.calls, [
      'upload:0:/tmp/a.jpg:true',
      'upload:1:/tmp/b.jpg:false',
      'update:true',
    ]);
  });

  test('finishWithoutVerification only updates profile', () async {
    final remote = _FakeRemote();
    final repo = OnboardingRepositoryImpl(remote);
    final r = await repo.finishWithoutVerification(
      OnboardingSubmitPayload(
        genderDb: 'MALE',
        birthDate: DateTime(1990, 5, 5),
        country: 'Sénégal',
        faithConfession: 'Catholique',
        maritalStatusDb: 'DIVORCED',
        whyMarriage: 'Famille',
      ),
    );
    expect(r, isA<Ok<void>>());
    expect(remote.calls, ['update:true']);
  });

  test('maps remote ServerException to ServerFailure', () async {
    final remote = _FakeRemote()..throwOnUpdate = const ServerException('boom');
    final repo = OnboardingRepositoryImpl(remote);
    final r = await repo.finishWithoutVerification(payload);
    expect(r, isA<Err<void>>());
    expect((r as Err).failure, isA<ServerFailure>());
  });
}
