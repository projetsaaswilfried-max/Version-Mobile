import 'package:equatable/equatable.dart';

import '../../domain/entities/account_person.dart';

class AccountPeopleState extends Equatable {
  const AccountPeopleState({
    this.people = const [],
    this.query = '',
    this.count,
    this.revealIdentities = true,
    this.isInitialLoading = false,
    this.errorMessage,
  });

  final List<AccountPerson> people;
  final String query;
  final int? count;
  final bool revealIdentities;
  final bool isInitialLoading;
  final String? errorMessage;

  List<AccountPerson> get visible {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return people;
    return [
      for (final person in people)
        if (person.displayName.toLowerCase().contains(q)) person,
    ];
  }

  AccountPeopleState copyWith({
    List<AccountPerson>? people,
    String? query,
    int? count,
    bool? revealIdentities,
    bool? isInitialLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AccountPeopleState(
      people: people ?? this.people,
      query: query ?? this.query,
      count: count ?? this.count,
      revealIdentities: revealIdentities ?? this.revealIdentities,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    people,
    query,
    count,
    revealIdentities,
    isInitialLoading,
    errorMessage,
  ];
}
