import 'package:equatable/equatable.dart';

import 'profile_field_keys.dart';

class ProfileCompleteness extends Equatable {
  const ProfileCompleteness({
    required this.isComplete,
    required this.missingKeys,
  });

  final bool isComplete;
  final List<String> missingKeys;

  /// Pourcentage de complétude (0-100), basé sur [ProfileFieldKeys.total].
  int get percentComplete {
    final done = ProfileFieldKeys.total - missingKeys.length;
    return ((done / ProfileFieldKeys.total) * 100).round().clamp(0, 100);
  }

  @override
  List<Object?> get props => [isComplete, missingKeys];
}
