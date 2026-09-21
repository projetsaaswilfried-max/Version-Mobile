import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Toast maison, inséré dans l'overlay racine (`Overlay.of(context,
/// rootOverlay: true)`) — contrairement au SnackBar Material
/// (`ScaffoldMessenger.of(context)`), il reste visible même au-dessus d'un
/// bottom sheet ouvert (qui a son propre Scaffold ambiant, derrière lequel
/// un SnackBar classique se retrouve caché).
class AppToast {
  const AppToast._();

  static OverlayEntry? _current;

  static void show(
    BuildContext context,
    String message, {
    bool isError = true,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _AppToastView(
        message: message,
        isError: isError,
        onDone: () {
          entry.remove();
          if (identical(_current, entry)) _current = null;
        },
      ),
    );

    // Insérer pendant un build en cours (ex. juste après la fermeture d'un
    // bottom sheet, quand un changement de TickerMode relance une
    // souscription Riverpod en attente) déclenche "setState() called during
    // build" — on reporte donc l'insertion au frame suivant.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _current?.remove();
      _current = entry;
      overlay.insert(entry);
    });
  }
}

class _AppToastView extends StatefulWidget {
  const _AppToastView({
    required this.message,
    required this.isError,
    required this.onDone,
  });

  final String message;
  final bool isError;
  final VoidCallback onDone;

  @override
  State<_AppToastView> createState() => _AppToastViewState();
}

class _AppToastViewState extends State<_AppToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(const Duration(seconds: 3), _dismiss);
  }

  Future<void> _dismiss() async {
    _timer?.cancel();
    if (!mounted) return;
    await _controller.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Positioned(
      top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      child: FadeTransition(
        opacity: _controller,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.isError ? colors.error : colors.textPrimary,
                  borderRadius: AppRadius.lgRadius,
                  boxShadow: AppShadows.md,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.isError
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        color: colors.onScrim,
                        size: AppSpacing.lg,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: typography.bodyMedium.copyWith(
                            color: colors.onScrim,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
