import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/discover_profile.dart';
import '../../domain/entities/discover_query.dart';
import '../../domain/premium/discover_premium_gate.dart';
import '../discover_controller.dart';
import '../discover_open_profile_sheet.dart';
import '../discover_state.dart';
import '../widgets/discover_filters_sheet.dart';
import '../widgets/discover_verify_sheet.dart';

/// Page de recherche Découvrir dédiée (D-search) : la barre épinglée sur
/// Découvrir poussait le bottom nav quand le clavier s'ouvrait — remplacée
/// par une icône qui ouvre cette page plein écran.
class DiscoverSearchPage extends ConsumerStatefulWidget {
  const DiscoverSearchPage({super.key});

  @override
  ConsumerState<DiscoverSearchPage> createState() =>
      _DiscoverSearchPageState();
}

class _DiscoverSearchPageState extends ConsumerState<DiscoverSearchPage> {
  late final TextEditingController _controller;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    final initial = ref.read(discoverControllerProvider).query.search ?? '';
    _controller = TextEditingController(text: initial);
    _controller.addListener(_onTextChanged);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      ref.read(discoverControllerProvider.notifier).loadMore();
    }
  }

  void _submit() {
    final current = ref.read(discoverControllerProvider).query;
    ref
        .read(discoverControllerProvider.notifier)
        .applyQuery(
          DiscoverQuery(
            search: _controller.text,
            city: current.city,
            denomination: current.denomination,
            profession: current.profession,
          ),
        );
  }

  void _clear() {
    _controller.clear();
    ref.read(discoverControllerProvider.notifier).clearQuery();
  }

  void _onFilters() {
    final current = ref.read(discoverControllerProvider).query;
    DiscoverFiltersSheet.show(
      context,
      initialQuery: current,
      onApply: (filters) {
        ref
            .read(discoverControllerProvider.notifier)
            .applyQuery(
              DiscoverQuery(
                search: current.search,
                city: filters.city,
                denomination: filters.denomination,
                profession: filters.profession,
              ),
            );
      },
      onReset: () {
        ref.read(discoverControllerProvider.notifier).clearQuery();
        _controller.clear();
      },
    );
  }

  void _onVerifyProfile() {
    AppToast.show(
      context,
      'Vérification du profil : bientôt',
      isError: false,
    );
  }

  void _onProfileTap(DiscoverProfile profile, DiscoverState state) {
    openDiscoverProfileSheet(
      context,
      profile: profile,
      state: state,
      onVerifyProfile: _onVerifyProfile,
    );
  }

  Future<void> _close() async {
    // On quitte la recherche : la fiche Découvrir en dessous partage le même
    // provider, on lui rend son flux normal (recommandé + autres profils).
    await ref.read(discoverControllerProvider.notifier).clearQuery();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoverControllerProvider);
    final colors = context.colors;
    final hasQuery = state.query.search != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_close());
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Retour',
                      onPressed: _close,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: AppTextField(
                        controller: _controller,
                        dense: true,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _submit(),
                        hint: 'Rechercher un profil',
                        prefixIcon: IconButton(
                          tooltip: 'Rechercher',
                          onPressed: _submit,
                          icon: Icon(
                            Icons.search,
                            color: colors.textSecondary,
                          ),
                        ),
                        suffixIcon: _controller.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Effacer',
                                onPressed: _clear,
                                icon: Icon(
                                  Icons.close,
                                  color: colors.textSecondary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Tooltip(
                      message: 'Filtres',
                      child: Material(
                        color: colors.chipBackground,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _onFilters,
                          child: SizedBox(
                            width: AppSpacing.inputHeight,
                            height: AppSpacing.inputHeight,
                            child: Icon(
                              Icons.tune,
                              size: AppSpacing.lg,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _body(state, hasQuery)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(DiscoverState state, bool hasQuery) {
    if (!hasQuery) {
      return const AppEmptyState(
        icon: Icons.search,
        title: 'Recherche un profil',
        detail: 'Tape un nom ou une ville, puis valide.',
      );
    }
    if (state.isLoadingMore && state.others.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.others.isEmpty) {
      return const AppEmptyState(
        icon: Icons.search_off,
        title: 'Aucun profil trouvé',
        detail: 'Essaie un autre nom ou une autre ville.',
      );
    }
    return AppProfileGrid(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: state.others.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.others.length) {
          return const Center(child: CircularProgressIndicator());
        }
        final profile = state.others[index];
        final age = profile.ageLabel ?? profile.age?.toString();
        final subtitleParts = [
          if (age != null && age.isNotEmpty) age,
          if (profile.city != null && profile.city!.isNotEmpty) profile.city!,
        ];
        return AppProfileGridCard(
          title: profile.displayName,
          photoUrl: profile.photoUrl,
          subtitle: subtitleParts.join(' · '),
          onTap: () => _onProfileTapGuarded(profile, state),
        );
      },
    );
  }

  void _onProfileTapGuarded(DiscoverProfile profile, DiscoverState state) {
    // Ouvrir la fiche est débloqué par la vérification du visiteur (Q1) —
    // pas par le Premium.
    final canOpen = canOpenDiscoverProfile(
      visitorVerified: state.visitorVerified,
      isStaff: state.visitorIsStaff,
    );
    if (!canOpen) {
      DiscoverVerifySheet.show(context, onVerify: _onVerifyProfile);
      return;
    }
    _onProfileTap(profile, state);
  }
}
