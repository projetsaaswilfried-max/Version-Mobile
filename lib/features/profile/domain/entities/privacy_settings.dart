import 'package:equatable/equatable.dart';

class PrivacySwitch extends Equatable {
  const PrivacySwitch({
    required this.id,
    required this.label,
    required this.value,
  });

  final String id;
  final String label;
  final bool value;

  PrivacySwitch copyWith({bool? value}) {
    return PrivacySwitch(id: id, label: label, value: value ?? this.value);
  }

  @override
  List<Object?> get props => [id, label, value];
}

class PrivacySettings extends Equatable {
  const PrivacySettings({this.switches = const []});

  final List<PrivacySwitch> switches;

  bool get isEmpty => switches.isEmpty;

  PrivacySettings toggling(String id, bool value) {
    return PrivacySettings(
      switches: [
        for (final item in switches)
          if (item.id == id) item.copyWith(value: value) else item,
      ],
    );
  }

  @override
  List<Object?> get props => [switches];
}
