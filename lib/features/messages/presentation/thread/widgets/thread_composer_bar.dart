import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';

class ThreadComposerBar extends StatefulWidget {
  const ThreadComposerBar({
    super.key,
    required this.enabled,
    required this.sending,
    required this.onSend,
    required this.onAttach,
  });

  final bool enabled;
  final bool sending;
  final ValueChanged<String> onSend;
  final VoidCallback onAttach;

  @override
  State<ThreadComposerBar> createState() => _ThreadComposerBarState();
}

class _ThreadComposerBarState extends State<ThreadComposerBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text;
    if (text.trim().isEmpty || widget.sending || !widget.enabled) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canSend = widget.enabled && !widget.sending;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Joindre',
              onPressed: canSend ? widget.onAttach : null,
              constraints: const BoxConstraints(
                minWidth: AppSpacing.xxxl,
                minHeight: AppSpacing.xxxl,
              ),
              icon: Icon(Icons.add, color: colors.primary),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled && !widget.sending,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'Écrire un message…',
                  filled: true,
                  fillColor: colors.border,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  border: const OutlineInputBorder(
                    borderRadius: AppRadius.pillRadius,
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: AppRadius.pillRadius,
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: AppRadius.pillRadius,
                    borderSide: BorderSide.none,
                  ),
                  disabledBorder: const OutlineInputBorder(
                    borderRadius: AppRadius.pillRadius,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Tooltip(
              message: 'Envoyer',
              child: FilledButton(
                key: const Key('thread-send'),
                onPressed: canSend ? _submit : null,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onScrim,
                  disabledBackgroundColor: colors.primary.withValues(
                    alpha: 0.4,
                  ),
                  shape: const CircleBorder(),
                  minimumSize: const Size(AppSpacing.xxxl, AppSpacing.xxxl),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                child: widget.sending
                    ? SizedBox(
                        width: AppSpacing.lg,
                        height: AppSpacing.lg,
                        child: CircularProgressIndicator(
                          strokeWidth: AppSpacing.xxs,
                          color: colors.onScrim,
                        ),
                      )
                    : Icon(
                        Icons.send,
                        size: AppSpacing.lg,
                        color: colors.onScrim,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
