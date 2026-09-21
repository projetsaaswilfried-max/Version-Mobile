import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_text_field.dart';

/// Filled search field with a leading loupe. Live filter via [onChanged].
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.hint = 'Rechercher',
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      hint: hint,
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      prefixIcon: Icon(Icons.search, color: context.colors.textSecondary),
      dense: true,
    );
  }
}
