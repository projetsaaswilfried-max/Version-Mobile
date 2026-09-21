import 'dart:developer' as developer;

import '../../../../core/error/failure.dart';
import '../../../../core/error/map_data_exception.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/onboarding_submit_payload.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_remote_datasource.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this._remote);

  final OnboardingRemoteDataSource _remote;

  @override
  Future<Result<void>> submit(OnboardingSubmitPayload payload) async {
    try {
      final paths = payload.photoPaths.where((p) => p.isNotEmpty).toList();
      if (paths.isEmpty) {
        return const Err(ValidationFailure('Ajoute une photo pour terminer.'));
      }
      for (var i = 0; i < paths.length; i++) {
        await _remote.uploadPhoto(
          localPath: paths[i],
          slot: i,
          isPrimary: i == 0,
        );
      }
      await _remote.updateFromPayload(payload, onboardingCompleted: true);
      return const Ok(null);
    } catch (error, stack) {
      developer.log(
        'Onboarding submit failed: $error',
        name: 'onboarding.repo',
        error: error,
        stackTrace: stack,
      );
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<void>> finishWithoutVerification(
    OnboardingSubmitPayload payload,
  ) async {
    try {
      await _remote.updateFromPayload(payload, onboardingCompleted: true);
      return const Ok(null);
    } catch (error, stack) {
      developer.log(
        'Onboarding finishWithoutVerification failed: $error',
        name: 'onboarding.repo',
        error: error,
        stackTrace: stack,
      );
      return Err(mapDataException(error));
    }
  }
}
