import 'package:equatable/equatable.dart';

class ProfileCompleteness extends Equatable {
  const ProfileCompleteness({
    required this.isComplete,
    required this.missingKeys,
  });

  final bool isComplete;
  final List<String> missingKeys;

  @override
  List<Object?> get props => [isComplete, missingKeys];
}
