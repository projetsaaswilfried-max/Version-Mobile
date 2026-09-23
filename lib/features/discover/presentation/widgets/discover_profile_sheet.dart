import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../di/discover_providers.dart';
import '../../domain/entities/discover_profile_detail.dart';
import '../../domain/premium/discover_premium_gate.dart';
import '../../../premium/presentation/widgets/premium_feature_sheet.dart';
import '../../../safety/presentation/widgets/profile_safety_sheet.dart';
import 'discover_error_state.dart';
import 'discover_invite_sheet.dart';
import 'discover_premium_sheet.dart';
import 'discover_profile_content.dart';
import 'discover_verify_sheet.dart';

class DiscoverProfileSheet extends ConsumerStatefulWidget {
  const DiscoverProfileSheet({
    super.key,
    required this.profileId,
    this.canLike = false,
    this.canFavorite = false,
    this.canInvite = false,
    this.visitorVerified = false,
    this.subscriptionStatus = 'FREE',
    this.visitorIsStaff = false,
    this.onVerifyProfile,
  });

  final String profileId;
  final bool canLike;
  final bool canFavorite;
  final bool canInvite;
  final bool visitorVerified;
  final String subscriptionStatus;
  final bool visitorIsStaff;
  final VoidCallback? onVerifyProfile;

  static Future<void> show(
    BuildContext context, {
    required String profileId,
    bool canLike = false,
    bool canFavorite = false,
    bool canInvite = false,
    bool visitorVerified = false,
    String subscriptionStatus = 'FREE',
    bool visitorIsStaff = false,
    VoidCallback? onVerifyProfile,
  }) {
    final colors = context.colors;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      barrierColor: colors.textPrimary.withValues(alpha: 0.45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        final maxHeight = MediaQuery.sizeOf(ctx).height * 0.9;
        return SizedBox(
          height: maxHeight,
          child: DiscoverProfileSheet(
            profileId: profileId,
            canLike: canLike,
            canFavorite: canFavorite,
            canInvite: canInvite,
            visitorVerified: visitorVerified,
            subscriptionStatus: subscriptionStatus,
            visitorIsStaff: visitorIsStaff,
            onVerifyProfile: onVerifyProfile,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<DiscoverProfileSheet> createState() =>
      _DiscoverProfileSheetState();
}

class _DiscoverProfileSheetState extends ConsumerState<DiscoverProfileSheet> {
  var _loading = true;
  String? _errorMessage;
  DiscoverProfileDetail? _detail;
  var _liked = false;
  var _likeBusy = false;
  var _favorited = false;
  var _favoriteBusy = false;
  var _inviteBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final result = await ref.read(getDiscoverProfileDetailProvider)(
      widget.profileId,
    );
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        unawaited(_recordView(value.id));
        final likedResult = await ref.read(isDiscoverProfileLikedProvider)(
          value.id,
        );
        if (!mounted) return;
        final liked = switch (likedResult) {
          Ok(value: final isLiked) => isLiked,
          Err() => false,
        };
        final favoritedResult = await ref.read(
          isDiscoverProfileFavoritedProvider,
        )(value.id);
        if (!mounted) return;
        final favorited = switch (favoritedResult) {
          Ok(value: final isFavorited) => isFavorited,
          Err() => false,
        };
        setState(() {
          _detail = value;
          _loading = false;
          _errorMessage = null;
          _liked = liked;
          _favorited = favorited;
        });
      case Err(:final failure):
        setState(() {
          _detail = null;
          _loading = false;
          _errorMessage = failure.message;
        });
    }
  }

  Future<void> _recordView(String id) async {
    final result = await ref.read(recordDiscoverProfileViewProvider)(id);
    if (result case Err(:final failure)) {
      debugPrint('record_profile_view: ${failure.message}');
    }
  }

  void _soon(String message) => AppToast.show(context, message);

  void _close() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  void _onLikePressed() {
    if (!widget.canLike) {
      DiscoverVerifySheet.show(context, onVerify: widget.onVerifyProfile);
      return;
    }
    unawaited(_toggleLike());
  }

  void _onFavoritePressed() {
    if (!widget.canFavorite) {
      if (!widget.visitorVerified) {
        DiscoverVerifySheet.show(context, onVerify: widget.onVerifyProfile);
        return;
      }
      DiscoverPremiumSheet.show(context);
      return;
    }
    unawaited(_toggleFavorite());
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteBusy) return;
    _favoriteBusy = true;
    final favorited = _favorited;
    final result = favorited
        ? await ref.read(unfavoriteDiscoverProfileProvider)(widget.profileId)
        : await ref.read(favoriteDiscoverProfileProvider)(widget.profileId);
    if (!mounted) return;
    _favoriteBusy = false;
    switch (result) {
      case Ok():
        setState(() => _favorited = !favorited);
      case Err(:final failure):
        final message = failure.message.trim().isEmpty
            ? 'Impossible de mettre en favori'
            : failure.message;
        _soon(message);
    }
  }

  void _onInvitePressed() {
    if (!widget.canInvite) {
      DiscoverVerifySheet.show(context, onVerify: widget.onVerifyProfile);
      return;
    }
    unawaited(_openInviteIfPremium());
  }

  Future<void> _openInviteIfPremium() async {
    if (_inviteBusy) return;
    if (!isPremiumActive(
      subscriptionStatus: widget.subscriptionStatus,
      isStaff: widget.visitorIsStaff,
    )) {
      await PremiumFeatureSheet.show(
        context,
        title: 'Envoyer une invitation',
        message: 'Passe Premium pour démarrer une conversation avec ce '
            'profil.',
      );
      return;
    }
    _inviteBusy = true;
    await DiscoverInviteSheet.show(
      context,
      profileId: widget.profileId,
      displayName: _detail?.displayName ?? '',
    );
    if (mounted) _inviteBusy = false;
  }

  Future<void> _toggleLike() async {
    if (_likeBusy) return;
    _likeBusy = true;
    final liked = _liked;
    final result = liked
        ? await ref.read(unlikeDiscoverProfileProvider)(widget.profileId)
        : await ref.read(likeDiscoverProfileProvider)(widget.profileId);
    if (!mounted) return;
    _likeBusy = false;
    switch (result) {
      case Ok():
        setState(() => _liked = !liked);
      case Err(:final failure):
        final message = failure.message.trim().isEmpty
            ? "Impossible d'aimer ce profil"
            : failure.message;
        _soon(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final detail = _detail;
    final showActions = !_loading && _errorMessage == null && detail != null;

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Container(
              width: AppSpacing.md,
              height: AppSpacing.xs,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: AppRadius.pillRadius,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Fermer',
                  onPressed: _close,
                  icon: Icon(Icons.close, color: colors.textPrimary),
                ),
                Expanded(
                  child: Text(
                    'Profil',
                    textAlign: TextAlign.center,
                    style: typography.title,
                  ),
                ),
                IconButton(
                  tooltip: 'Signaler ou bloquer',
                  onPressed: detail == null
                      ? null
                      : () async {
                          final blocked = await ProfileSafetySheet.present(
                            context: context,
                            ref: ref,
                            profileId: detail.id,
                          );
                          if (blocked && context.mounted) _close();
                        },
                  icon: Icon(Icons.more_horiz, color: colors.textPrimary),
                ),
              ],
            ),
          ),
          Expanded(child: _body(context)),
          if (showActions)
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                bottom > 0 ? bottom : AppSpacing.lg,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CircleAction(
                    tooltip: 'Like',
                    icon: _liked ? Icons.favorite : Icons.favorite_border,
                    active: _liked,
                    activeColor: colors.primary,
                    onPressed: _onLikePressed,
                  ),
                  _CircleAction(
                    tooltip: 'Favori',
                    icon: _favorited ? Icons.star : Icons.star_border,
                    active: _favorited,
                    activeColor: colors.warning,
                    onPressed: _onFavoritePressed,
                  ),
                  _CircleAction(
                    tooltip: 'Envoyer un message',
                    icon: Icons.send_rounded,
                    active: false,
                    activeColor: colors.primary,
                    onPressed: _onInvitePressed,
                    filled: true,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = _errorMessage;
    if (error != null) {
      return DiscoverErrorState(message: error, onRetry: _load);
    }
    final detail = _detail;
    if (detail == null) {
      return DiscoverErrorState(message: 'Profil introuvable.', onRetry: _load);
    }
    return DiscoverProfileContent(detail: detail);
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.tooltip,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onPressed,
    this.filled = false,
  });

  final String tooltip;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isHot = active || filled;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isHot ? activeColor : colors.surface,
        shape: CircleBorder(
          side: BorderSide(
            color: isHot ? activeColor : colors.border,
            width: 1.5,
          ),
        ),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: AppSpacing.xxxl + AppSpacing.sm,
            height: AppSpacing.xxxl + AppSpacing.sm,
            child: Icon(
              icon,
              color: isHot ? colors.onScrim : colors.textPrimary,
              size: AppSpacing.xl,
            ),
          ),
        ),
      ),
    );
  }
}
