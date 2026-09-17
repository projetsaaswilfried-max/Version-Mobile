import 'package:agapeo/core/error/exceptions.dart';
import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/profile/data/datasources/profile_gate_remote_datasource.dart';
import 'package:agapeo/features/profile/data/repositories/profile_gate_repository_impl.dart';
import 'package:agapeo/features/profile/domain/entities/member_gate_snapshot.dart';
import 'package:agapeo/features/profile/domain/entities/subscription_status.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeProfileGateRemoteDataSource implements ProfileGateRemoteDataSource {
  ({bool isSuspended, String subscriptionStatus, bool onboardingCompleted})?
      raw;
  Exception? toThrow;

  @override
  Future<
      ({
        bool isSuspended,
        String subscriptionStatus,
        bool onboardingCompleted,
      })> fetchGateRaw() async {
    if (toThrow != null) throw toThrow!;
    return raw!;
  }
}

void main() {
  late FakeProfileGateRemoteDataSource datasource;
  late ProfileGateRepositoryImpl repository;

  setUp(() {
    datasource = FakeProfileGateRemoteDataSource();
    repository = ProfileGateRepositoryImpl(datasource);
  });

  test('maps EXPIRED subscription_status to SubscriptionStatus.expired',
      () async {
    datasource.raw = (
      isSuspended: false,
      subscriptionStatus: 'EXPIRED',
      onboardingCompleted: true,
    );

    final result = await repository.fetchGate();

    expect(result, isA<Ok<MemberGateSnapshot>>());
    final snapshot = (result as Ok<MemberGateSnapshot>).value;
    expect(snapshot.subscriptionStatus, SubscriptionStatus.expired);
    expect(snapshot.isSuspended, isFalse);
    expect(snapshot.onboardingCompleted, isTrue);
  });

  test('maps unknown subscription_status to SubscriptionStatus.free', () async {
    datasource.raw = (
      isSuspended: false,
      subscriptionStatus: 'WEIRD',
      onboardingCompleted: true,
    );

    final result = await repository.fetchGate();

    expect(result, isA<Ok<MemberGateSnapshot>>());
    expect(
      (result as Ok<MemberGateSnapshot>).value.subscriptionStatus,
      SubscriptionStatus.free,
    );
  });

  test('maps empty subscription_status (null raw) to free', () async {
    datasource.raw = (
      isSuspended: false,
      subscriptionStatus: '',
      onboardingCompleted: true,
    );

    final result = await repository.fetchGate();

    expect(result, isA<Ok<MemberGateSnapshot>>());
    expect(
      (result as Ok<MemberGateSnapshot>).value.subscriptionStatus,
      SubscriptionStatus.free,
    );
  });

  test('maps onboardingCompleted false (null raw default) through', () async {
    datasource.raw = (
      isSuspended: false,
      subscriptionStatus: 'FREE',
      onboardingCompleted: false,
    );

    final result = await repository.fetchGate();

    expect(result, isA<Ok<MemberGateSnapshot>>());
    expect(
      (result as Ok<MemberGateSnapshot>).value.onboardingCompleted,
      isFalse,
    );
  });

  test('maps NetworkException to Err NetworkFailure', () async {
    datasource.toThrow = const NetworkException('offline');

    final result = await repository.fetchGate();

    expect(result, isA<Err<MemberGateSnapshot>>());
    final failure = (result as Err<MemberGateSnapshot>).failure;
    expect(failure, isA<NetworkFailure>());
    expect(failure.message, 'offline');
  });

  test('maps UnauthorizedException to Err UnauthorizedFailure', () async {
    datasource.toThrow = const UnauthorizedException('Session expirée.');

    final result = await repository.fetchGate();

    expect(result, isA<Err<MemberGateSnapshot>>());
    expect(
      (result as Err<MemberGateSnapshot>).failure,
      isA<UnauthorizedFailure>(),
    );
  });

  test('maps ACTIVE / CANCELED / FREE strings to matching enums', () async {
    for (final entry in [
      ('ACTIVE', SubscriptionStatus.active),
      ('CANCELED', SubscriptionStatus.canceled),
      ('FREE', SubscriptionStatus.free),
    ]) {
      datasource.raw = (
        isSuspended: true,
        subscriptionStatus: entry.$1,
        onboardingCompleted: false,
      );

      final result = await repository.fetchGate();
      final snapshot = (result as Ok<MemberGateSnapshot>).value;
      expect(snapshot.subscriptionStatus, entry.$2);
      expect(snapshot.isSuspended, isTrue);
    }
  });
}
