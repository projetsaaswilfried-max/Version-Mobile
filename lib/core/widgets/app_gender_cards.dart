import 'package:flutter/material.dart';

import 'app_option_chips.dart';

/// Single-select gender chips, Nestle interests style.
class AppGenderCards extends StatelessWidget {
  const AppGenderCards({
    super.key,
    required this.onSelected,
    this.selectedId,
    this.errorText,
    this.items = defaultItems,
  });

  final String? selectedId;
  final ValueChanged<String> onSelected;
  final String? errorText;
  final List<AppOptionItem> items;

  static const defaultItems = <AppOptionItem>[
    AppOptionItem(id: 'woman', label: 'Femme', icon: Icons.woman),
    AppOptionItem(id: 'man', label: 'Homme', icon: Icons.man),
  ];

  @override
  Widget build(BuildContext context) {
    return AppOptionChips(
      items: items,
      selectedId: selectedId,
      onSelected: onSelected,
      errorText: errorText,
    );
  }
}
