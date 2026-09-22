import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../di/support_providers.dart';
import '../domain/entities/support_ticket.dart';

class SupportThreadPage extends ConsumerStatefulWidget {
  const SupportThreadPage({super.key, required this.ticket});

  final SupportTicket ticket;

  @override
  ConsumerState<SupportThreadPage> createState() => _SupportThreadPageState();
}

class _SupportThreadPageState extends ConsumerState<SupportThreadPage> {
  final _input = TextEditingController();
  var _loading = true;
  var _sending = false;
  String? _error;
  List<SupportMessage> _messages = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ref
        .read(supportRepositoryProvider)
        .fetchMessages(widget.ticket.id);
    if (!mounted) return;
    switch (result) {
      case Ok<List<SupportMessage>>(:final value):
        setState(() {
          _messages = value;
          _loading = false;
        });
      case Err<List<SupportMessage>>(:final failure):
        setState(() {
          _error = failure.message;
          _loading = false;
        });
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending || !widget.ticket.isOpen) return;
    setState(() => _sending = true);
    final result = await ref
        .read(supportRepositoryProvider)
        .sendMessage(ticketId: widget.ticket.id, message: text);
    if (!mounted) return;
    setState(() => _sending = false);
    switch (result) {
      case Ok<void>():
        _input.clear();
        await _load();
      case Err<void>(:final failure):
        AppToast.show(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: Text(widget.ticket.subject)),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return Align(
                        alignment: message.isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: message.isMine
                                ? colors.primaryLight
                                : colors.surface,
                            borderRadius: BorderRadius.circular(AppSpacing.md),
                          ),
                          child: Text(message.body),
                        ),
                      );
                    },
                  ),
          ),
          if (widget.ticket.isOpen)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: AppTextField(hint: 'Répondre…', controller: _input),
                  ),
                  AppButton(
                    label: 'Envoyer',
                    expanded: false,
                    compact: true,
                    isLoading: _sending,
                    onPressed: _send,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
