import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../core/config/app_assets.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/app_svg.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../data/voice/record_voice_note_recorder.dart';
import '../../../domain/voice/voice_note_recorder.dart';
import '../voice_clock.dart';
import 'thread_voice_waveform.dart';

class ThreadComposerBar extends StatefulWidget {
  const ThreadComposerBar({
    super.key,
    required this.enabled,
    required this.sending,
    required this.onSend,
    required this.onAttach,
    required this.onSendVoice,
    this.recorder,
  });

  final bool enabled;
  final bool sending;
  final ValueChanged<String> onSend;
  final VoidCallback onAttach;
  final void Function(String path, int durationSeconds) onSendVoice;
  final VoiceNoteRecorder? recorder;

  @override
  State<ThreadComposerBar> createState() => _ThreadComposerBarState();
}

class _ThreadComposerBarState extends State<ThreadComposerBar> {
  final _controller = TextEditingController();
  VoiceNoteRecorder? _createdRecorder;
  var _recording = false;
  var _elapsed = Duration.zero;
  Timer? _ticker;
  StreamSubscription<double>? _ampSub;
  var _samples = const <double>[];
  String? _path;

  VoiceNoteRecorder get _recorder {
    final injected = widget.recorder;
    if (injected != null) return injected;
    return _createdRecorder ??= RecordVoiceNoteRecorder();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(_ampSub?.cancel());
    if (_recording) {
      unawaited(_recorder.cancel());
    }
    final created = _createdRecorder;
    if (created != null) {
      unawaited(created.dispose());
    }
    _controller.dispose();
    super.dispose();
  }

  bool get _hasText => _controller.text.trim().isNotEmpty;

  void _submit() {
    final text = _controller.text;
    if (text.trim().isEmpty || widget.sending || !widget.enabled) return;
    widget.onSend(text);
    _controller.clear();
    setState(() {});
  }

  Future<void> _startRecording() async {
    if (!widget.enabled || widget.sending || _recording) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final allowed = await _recorder.hasPermission();
    if (!mounted) return;
    if (!allowed) {
      AppToast.show(context, 'Autorise le micro pour envoyer une note vocale.');
      return;
    }
    final path =
        '${Directory.systemTemp.path}/agapeo-voice-${DateTime.now().millisecondsSinceEpoch}.m4a';
    try {
      await _recorder.start(path: path);
    } catch (_) {
      if (mounted) {
        AppToast.show(context, 'Impossible d\'enregistrer.');
      }
      return;
    }
    if (!mounted) return;
    await _ampSub?.cancel();
    _ampSub = _recorder
        .amplitude(interval: const Duration(milliseconds: 80))
        .listen((value) {
          if (!mounted) return;
          setState(() {
            final next = [..._samples, value];
            _samples = next.length > 48 ? next.sublist(next.length - 48) : next;
          });
        });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_recording) return;
      final next = _elapsed + const Duration(seconds: 1);
      setState(() => _elapsed = next);
      if (next.inSeconds >= kMaxVoiceNoteSeconds) {
        unawaited(_stopAndSend());
      }
    });
    setState(() {
      _recording = true;
      _path = path;
      _elapsed = Duration.zero;
      _samples = const [];
    });
  }

  Future<void> _cancelRecording() async {
    if (!_recording) return;
    _ticker?.cancel();
    unawaited(_ampSub?.cancel());
    _ampSub = null;
    try {
      await _recorder.cancel();
    } catch (_) {}
    final path = _path;
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
    if (!mounted) return;
    setState(() {
      _recording = false;
      _path = null;
      _elapsed = Duration.zero;
      _samples = const [];
    });
  }

  Future<void> _stopAndSend() async {
    if (!_recording || widget.sending) return;
    _ticker?.cancel();
    unawaited(_ampSub?.cancel());
    _ampSub = null;
    final elapsed = _elapsed;
    String? path;
    try {
      path = await _recorder.stop() ?? _path;
    } catch (_) {
      path = _path;
    }
    if (!mounted) return;
    setState(() {
      _recording = false;
      _path = null;
      _elapsed = Duration.zero;
      _samples = const [];
    });
    final seconds = elapsed.inSeconds;
    if (path == null || seconds < kMinVoiceNoteSeconds) {
      if (path != null) {
        final file = File(path);
        if (file.existsSync()) {
          try {
            await file.delete();
          } catch (_) {}
        }
      }
      if (!mounted) return;
      AppToast.show(context, 'Note vocale trop courte.');
      return;
    }
    widget.onSendVoice(path, seconds);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canAct = widget.enabled && !widget.sending;
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
              tooltip: _recording ? 'Annuler' : 'Joindre',
              onPressed: !canAct
                  ? null
                  : _recording
                  ? _cancelRecording
                  : widget.onAttach,
              constraints: const BoxConstraints(
                minWidth: AppSpacing.xxxl,
                minHeight: AppSpacing.xxxl,
              ),
              icon: AppSvg(
                _recording ? AppAssets.icTrash : AppAssets.icPaperclip,
                size: AppSpacing.lg,
                color: !canAct
                    ? colors.muted
                    : _recording
                    ? colors.textSecondary
                    : colors.primary,
              ),
            ),
            Expanded(
              child: _recording
                  ? _RecordingPill(elapsed: _elapsed, samples: _samples)
                  : TextField(
                      controller: _controller,
                      enabled: widget.enabled && !widget.sending,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: 'Écrire un message…',
                        filled: true,
                        fillColor: colors.chipBackground,
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
              message: _recording
                  ? 'Envoyer la note vocale'
                  : _hasText
                  ? 'Envoyer'
                  : 'Note vocale',
              child: FilledButton(
                key: const Key('thread-send'),
                onPressed: !canAct
                    ? null
                    : _recording
                    ? _stopAndSend
                    : _hasText
                    ? _submit
                    : _startRecording,
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
                    : AppSvg(
                        _recording || _hasText
                            ? AppAssets.icSend
                            : AppAssets.icMic,
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

class _RecordingPill extends StatelessWidget {
  const _RecordingPill({required this.elapsed, required this.samples});

  final Duration elapsed;
  final List<double> samples;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.chipBackground,
        borderRadius: AppRadius.pillRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            _RecordingDot(color: colors.error),
            const SizedBox(width: AppSpacing.sm),
            Text(
              formatVoiceClock(elapsed.inSeconds),
              style: context.typography.bodyMedium,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ThreadVoiceWaveform(samples: samples, color: colors.error),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordingDot extends StatefulWidget {
  const _RecordingDot({required this.color});

  final Color color;

  @override
  State<_RecordingDot> createState() => _RecordingDotState();
}

class _RecordingDotState extends State<_RecordingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_controller),
      child: DecoratedBox(
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
        child: const SizedBox(width: AppSpacing.sm, height: AppSpacing.sm),
      ),
    );
  }
}
