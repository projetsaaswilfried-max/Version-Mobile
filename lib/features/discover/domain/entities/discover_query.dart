import 'package:equatable/equatable.dart';

class DiscoverQuery extends Equatable {
  const DiscoverQuery({
    this.search,
    this.city,
    this.denomination,
    this.profession,
  });

  final String? search;
  final String? city;
  final String? denomination;

  /// Conservé pour le sheet V1. Pas de champ métier sur [DiscoverProfile]
  /// (absent du select candidats) : le filtre liste l'ignore.
  final String? profession;

  bool get isEmpty =>
      _isBlank(search) &&
      _isBlank(city) &&
      _isBlank(denomination) &&
      _isBlank(profession);

  /// Filtres du sheet (hors champ recherche dédié).
  bool get hasSheetFilters =>
      !_isBlank(city) || !_isBlank(denomination) || !_isBlank(profession);

  /// Recherche ou filtres sheet actifs.
  bool get hasActiveConstraints => !isEmpty;

  DiscoverQuery get normalized => DiscoverQuery(
    search: _nullIfBlank(search),
    city: _nullIfBlank(city),
    denomination: _nullIfBlank(denomination),
    profession: _nullIfBlank(profession),
  );

  DiscoverQuery copyWith({
    String? search,
    bool clearSearch = false,
    String? city,
    bool clearCity = false,
    String? denomination,
    bool clearDenomination = false,
    String? profession,
    bool clearProfession = false,
  }) {
    return DiscoverQuery(
      search: clearSearch ? null : (search ?? this.search),
      city: clearCity ? null : (city ?? this.city),
      denomination: clearDenomination
          ? null
          : (denomination ?? this.denomination),
      profession: clearProfession ? null : (profession ?? this.profession),
    );
  }

  @override
  List<Object?> get props => [search, city, denomination, profession];
}

bool _isBlank(String? value) => value == null || value.trim().isEmpty;

String? _nullIfBlank(String? value) {
  if (_isBlank(value)) return null;
  return value!.trim();
}
