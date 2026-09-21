import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_assets.dart';
import '../../../core/error/result.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../di/support_providers.dart';
import '../domain/entities/support_ticket.dart';
import 'support_compose_page.dart';
import 'support_thread_page.dart';

class SupportListPage extends ConsumerStatefulWidget {
  const SupportListPage({super.key});

  @override
  ConsumerState<SupportListPage> createState() => _SupportListPageState();
}

class _SupportListPageState extends ConsumerState<SupportListPage> {
  var _loading = true;
  String? _error;
  var _expired = false;
  List<SupportTicket> _tickets = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final expired = await ref.read(supportRepositoryProvider).isExpired();
    if (!mounted) return;
    if (expired case Ok<bool>(value: true)) {
      setState(() {
        _expired = true;
        _loading = false;
      });
      return;
    }
    final result = await ref.read(supportRepositoryProvider).fetchTickets();
    if (!mounted) return;
    switch (result) {
      case Ok<List<SupportTicket>>(:final value):
        setState(() {
          _tickets = value;
          _loading = false;
        });
      case Err<List<SupportTicket>>(:final failure):
        setState(() {
          _error = failure.message;
          _loading = false;
        });
    }
  }

  bool get _hasOpen => _tickets.any((ticket) => ticket.isOpen);

  Future<void> _openCompose() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SupportComposePage()),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _expired
          ? const AppEmptyState(
              icon: Icons.lock_outline,
              title: 'Support indisponible',
              detail:
                  'Le support n\'est pas disponible avec un abonnement expiré.',
            )
          : _error != null
          ? AppEmptyState(
              icon: Icons.error_outline,
              title: 'Impossible de charger',
              detail: _error,
              actionLabel: 'Réessayer',
              actionVariant: AppButtonVariant.primary,
              onAction: _load,
            )
          : Column(
              children: [
                if (!_hasOpen && _tickets.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: AppButton(
                      label: 'Ouvrir un dossier',
                      onPressed: () => _openCompose(),
                    ),
                  ),
                Expanded(
                  child: _tickets.isEmpty
                      ? AppEmptyState(
                          illustrationAsset: AppAssets.emptyAccount,
                          icon: Icons.support_agent_outlined,
                          title: 'Aucun dossier',
                          detail:
                              'Écris-nous si tu as une question ou un problème.',
                          actionLabel: 'Ouvrir un dossier',
                          actionVariant: AppButtonVariant.primary,
                          onAction: () => _openCompose(),
                        )
                      : ListView.builder(
                          itemCount: _tickets.length,
                          itemBuilder: (context, index) {
                            final ticket = _tickets[index];
                            return ListTile(
                              title: Text(ticket.subject),
                              subtitle: Text(
                                ticket.isOpen ? 'Ouvert' : 'Fermé',
                              ),
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        SupportThreadPage(ticket: ticket),
                                  ),
                                );
                                await _load();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
