import 'package:equatable/equatable.dart';

class AccountPerson extends Equatable {
  const AccountPerson({
    required this.id,
    required this.displayName,
    this.photoUrl,
    this.city,
    this.identityRevealed = true,
  });

  final String id;
  final String displayName;
  final String? photoUrl;
  final String? city;
  final bool identityRevealed;

  @override
  List<Object?> get props => [
    id,
    displayName,
    photoUrl,
    city,
    identityRevealed,
  ];
}

class InterestedPeople extends Equatable {
  const InterestedPeople({
    required this.count,
    required this.revealIdentities,
    this.people = const [],
  });

  final int count;
  final bool revealIdentities;
  final List<AccountPerson> people;

  @override
  List<Object?> get props => [count, revealIdentities, people];
}
