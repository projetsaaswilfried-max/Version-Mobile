import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/profile/domain/entities/faith_details.dart';
import 'package:agapeo/features/profile/domain/entities/more_info_details.dart';
import 'package:agapeo/features/profile/domain/usecases/save_faith_details.dart';
import 'package:agapeo/features/profile/domain/usecases/save_more_info_details.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/profile_account_test_fakes.dart';

void main() {
  test('SaveFaithDetails rejects a verse over 200 chars', () async {
    final repo = FakeProfileAccountRepository();
    final result = await SaveFaithDetails(repo)(
      FaithDetails(verse: 'x' * 201, verseAvailable: true),
    );
    expect(result, isA<Err<void>>());
  });

  test('SaveMoreInfoDetails rejects more than 10 qualities', () async {
    final repo = FakeProfileAccountRepository();
    final result = await SaveMoreInfoDetails(repo)(
      MoreInfoDetails(
        qualities: List.generate(11, (i) => 'q$i'),
        qualitiesAvailable: true,
      ),
    );
    expect(result, isA<Err<void>>());
  });

  test('SaveFaithDetails persists a valid payload', () async {
    final repo = FakeProfileAccountRepository();
    final result = await SaveFaithDetails(repo)(
      const FaithDetails(denomination: 'Catholique'),
    );
    expect(result, isA<Ok<void>>());
    expect(repo.faith.denomination, 'Catholique');
  });
}
