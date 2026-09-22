import 'package:equatable/equatable.dart';

class DiscoverQuery extends Equatable {
  const DiscoverQuery({
    this.search,
    this.country,
    this.city,
    this.profession,
    this.denominations = const [],
    this.maritalStatuses = const [],
    this.ageMin,
    this.ageMax,
  });

  static const int minAge = 18;
  static const int maxAge = 80;

  final String? search;
  final String? country;
  final String? city;
  final String? profession;
  final List<String> denominations;
  final List<String> maritalStatuses;
  final int? ageMin;
  final int? ageMax;

  bool get isEmpty =>
      _isBlank(search) &&
      _isBlank(country) &&
      _isBlank(city) &&
      _isBlank(profession) &&
      denominations.isEmpty &&
      maritalStatuses.isEmpty &&
      !_hasAgeConstraint;

  bool get hasSheetFilters =>
      !_isBlank(country) ||
      !_isBlank(city) ||
      !_isBlank(profession) ||
      denominations.isNotEmpty ||
      maritalStatuses.isNotEmpty ||
      _hasAgeConstraint;

  bool get hasActiveConstraints => !isEmpty;

  bool get _hasAgeConstraint =>
      _effectiveAgeMin != null || _effectiveAgeMax != null;

  int? get _effectiveAgeMin {
    final value = ageMin;
    if (value == null || value <= minAge) return null;
    return value;
  }

  int? get _effectiveAgeMax {
    final value = ageMax;
    if (value == null || value >= maxAge) return null;
    return value;
  }

  DiscoverQuery get normalized => DiscoverQuery(
    search: _nullIfBlank(search),
    country: _nullIfBlank(country),
    city: _nullIfBlank(city),
    profession: _nullIfBlank(profession),
    denominations: _sortedUnique(denominations),
    maritalStatuses: _sortedUnique(maritalStatuses),
    ageMin: _effectiveAgeMin,
    ageMax: _effectiveAgeMax,
  );

  DiscoverQuery copyWith({
    String? search,
    bool clearSearch = false,
    String? country,
    bool clearCountry = false,
    String? city,
    bool clearCity = false,
    String? profession,
    bool clearProfession = false,
    List<String>? denominations,
    List<String>? maritalStatuses,
    int? ageMin,
    bool clearAgeMin = false,
    int? ageMax,
    bool clearAgeMax = false,
  }) {
    return DiscoverQuery(
      search: clearSearch ? null : (search ?? this.search),
      country: clearCountry ? null : (country ?? this.country),
      city: clearCity ? null : (city ?? this.city),
      profession: clearProfession ? null : (profession ?? this.profession),
      denominations: denominations ?? this.denominations,
      maritalStatuses: maritalStatuses ?? this.maritalStatuses,
      ageMin: clearAgeMin ? null : (ageMin ?? this.ageMin),
      ageMax: clearAgeMax ? null : (ageMax ?? this.ageMax),
    );
  }

  @override
  List<Object?> get props => [
    search,
    country,
    city,
    profession,
    denominations.join('|'),
    maritalStatuses.join('|'),
    ageMin,
    ageMax,
  ];
}

bool _isBlank(String? value) => value == null || value.trim().isEmpty;

String? _nullIfBlank(String? value) {
  if (_isBlank(value)) return null;
  return value!.trim();
}

List<String> _sortedUnique(List<String> values) {
  final unique = <String>{};
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) unique.add(trimmed);
  }
  final list = unique.toList()..sort();
  return list;
}
