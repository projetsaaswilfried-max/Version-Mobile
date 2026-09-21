import 'package:agapeo/features/profile/data/blocked_profiles_rpc.dart';
import 'package:agapeo/features/profile/domain/entities/account_person.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseBlockedProfilesRpc', () {
    test('parses profile rows with names', () {
      final people = parseBlockedProfilesRpc([
        {
          'id': 'u1',
          'first_name': 'Léa',
          'last_name': 'Martin',
          'city': 'Paris',
          'avatar_url': 'https://example.com/a.jpg',
        },
      ]);
      expect(people, [
        const AccountPerson(
          id: 'u1',
          displayName: 'Léa Martin',
          city: 'Paris',
          photoUrl: 'https://example.com/a.jpg',
        ),
      ]);
    });

    test('parses nested profile and blocked_id', () {
      final people = parseBlockedProfilesRpc([
        {
          'blocked_id': 'u2',
          'profile': {'first_name': 'Marc', 'last_name': 'Dupont'},
        },
      ]);
      expect(people.single.id, 'u2');
      expect(people.single.displayName, 'Marc Dupont');
    });

    test('parses bare uuid list', () {
      final people = parseBlockedProfilesRpc(['u3', '  ']);
      expect(people, [
        const AccountPerson(id: 'u3', displayName: 'Profil bloqué'),
      ]);
    });
  });

  group('mergeBlockedPeople', () {
    test('keeps placeholders when profiles are hidden by RLS', () {
      final merged = mergeBlockedPeople(
        ids: const ['a', 'b'],
        hydrated: const [
          AccountPerson(id: 'a', displayName: 'Alice', city: 'Lyon'),
        ],
      );
      expect(merged, [
        const AccountPerson(id: 'a', displayName: 'Alice', city: 'Lyon'),
        const AccountPerson(id: 'b', displayName: 'Profil bloqué'),
      ]);
    });
  });
}
