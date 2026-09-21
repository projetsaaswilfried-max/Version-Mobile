import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/config/app_assets.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../domain/entities/account_person.dart';

class AccountPersonTile extends StatelessWidget {
  const AccountPersonTile({
    super.key,
    required this.person,
    this.onTap,
    this.trailing,
  });

  final AccountPerson person;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      minVerticalPadding: AppSpacing.md,
      leading: SizedBox(
        width: AppSpacing.xxxl,
        height: AppSpacing.xxxl,
        child: person.photoUrl != null
            ? CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(person.photoUrl!),
              )
            : AppAvatarPlaceholder(
                name: person.displayName,
                circle: true,
                iconSize: AppSpacing.xl,
              ),
      ),
      title: Text(person.displayName, style: context.typography.bodyLarge),
      subtitle: person.city == null
          ? null
          : Text(person.city!, style: context.typography.bodySmall),
      trailing:
          trailing ?? Icon(Icons.chevron_right, color: colors.textSecondary),
    );
  }
}

class AccountEmptyState extends StatelessWidget {
  const AccountEmptyState({
    super.key,
    required this.message,
    this.detail,
    this.icon = Icons.people_outline,
  });

  final String message;
  final String? detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      illustrationAsset: AppAssets.emptyAccount,
      title: message,
      detail: detail,
      icon: icon,
    );
  }
}

class AccountSearchField extends StatelessWidget {
  const AccountSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: AppSearchField(controller: controller, onChanged: onChanged),
    );
  }
}

class AccountSectionRow extends StatelessWidget {
  const AccountSectionRow({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return AppSettingsRow(
      label: label,
      icon: icon,
      danger: danger,
      onTap: onTap,
    );
  }
}

class TagField extends StatefulWidget {
  const TagField({
    super.key,
    required this.label,
    required this.hint,
    required this.tags,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final List<String> tags;
  final int max;
  final ValueChanged<List<String>> onChanged;

  @override
  State<TagField> createState() => _TagFieldState();
}

class _TagFieldState extends State<TagField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String value) {
    final next = value.trim();
    if (next.isEmpty || widget.tags.contains(next)) return;
    if (widget.tags.length >= widget.max) return;
    widget.onChanged([...widget.tags, next]);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: context.typography.bodyMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${widget.tags.length}/${widget.max} · ${widget.hint}',
          style: context.typography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final tag in widget.tags)
              InputChip(
                label: Text(tag),
                onDeleted: () => widget.onChanged(
                  widget.tags.where((item) => item != tag).toList(),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
          ],
        ),
        if (widget.tags.length < widget.max)
          AppTextField(
            hint: 'Ajouter',
            controller: _controller,
            textInputAction: TextInputAction.done,
            onSubmitted: _add,
          ),
      ],
    );
  }
}
