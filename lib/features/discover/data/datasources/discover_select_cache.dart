class DiscoverSelectCache {
  String? _visitorSelect;
  String? _candidateSelect;

  String? get({required bool single}) {
    return single ? _visitorSelect : _candidateSelect;
  }

  void set(String select, {required bool single}) {
    if (single) {
      _visitorSelect = select;
    } else {
      _candidateSelect = select;
    }
  }

  void clear({required bool single}) {
    if (single) {
      _visitorSelect = null;
    } else {
      _candidateSelect = null;
    }
  }
}

bool shouldFallbackDiscoverSelect({
  required String message,
  String? code,
  Object? details,
  Object? hint,
}) {
  final normalizedCode = (code ?? '').toUpperCase();
  if (normalizedCode == '42501' || normalizedCode == 'PGRST301') {
    return false;
  }
  if (normalizedCode == '414' || normalizedCode == '413') return true;
  final all = '$message ${details ?? ''} ${hint ?? ''} $normalizedCode'
      .toLowerCase();
  final missingColumn =
      (all.contains('column') && all.contains('does not exist')) ||
      all.contains('could not find') ||
      all.contains('relationship') ||
      all.contains('embedding');
  final oversized =
      all.contains('too long') ||
      all.contains('request uri') ||
      all.contains('payload too large');
  return missingColumn || oversized;
}
