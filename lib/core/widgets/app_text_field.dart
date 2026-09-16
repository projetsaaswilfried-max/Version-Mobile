import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Design-system text field — label above the input, consistent spacing
/// and error text, styled from `InputDecorationTheme` (see AppTheme).
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.focusNode,
    this.obscureText = false,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLength,
    this.inputFormatters,
    this.autofillHints,
    this.errorText,
    this.onChanged,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool obscureText;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: context.typography.label),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          autofocus: autofocus,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          autofillHints: autofillHints,
          onChanged: onChanged,
          style: context.typography.bodyLarge,
          buildCounter: maxLength != null
              ? (_, {required currentLength, required isFocused, maxLength}) =>
                  null
              : null,
          decoration: InputDecoration(hintText: hint, errorText: errorText),
        ),
      ],
    );
  }
}
