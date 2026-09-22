import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../domain/entities/message.dart';
import '../thread_time_labels.dart';
import '../voice_clock.dart';

class ThreadVoiceTile extends StatefulWidget {
  const ThreadVoiceTile({super.key, required this.message});

  final Message message;

  @override
  State<ThreadVoiceTile> createState() => _ThreadVoiceTileState();
}

class _ThreadVoiceTileState extends State<ThreadVoiceTile> {
  AudioPlayer? _player;
  final _subs = <StreamSubscription<dynamic>>[];
  var _playing = false;
  var _loading = false;
  var _position = Duration.zero;
  Duration? _duration;

  static const _loadTimeout = Duration(seconds: 12);
  static var _sessionReady = false;

  Message get _message => widget.message;

  String? get _url {
    final url = _message.mediaUrl?.trim();
    if (url == null || url.isEmpty) return null;
    return url;
  }

  int get _fallbackSeconds => _message.durationSeconds ?? 0;

  @override
  void dispose() {
    _ActiveVoice.release(this);
    _cancelSubs();
    _player?.dispose();
    super.dispose();
  }

  void _cancelSubs() {
    for (final sub in _subs) {
      unawaited(sub.cancel());
    }
    _subs.clear();
  }

  Future<void> _prepareSession() async {
    if (_sessionReady) return;
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    _sessionReady = true;
  }

  Future<File> _cachedFile(String url) async {
    final ext = _guessExtension(url);
    final file = File(
      '${Directory.systemTemp.path}/agapeo-voice-${_message.id}$ext',
    );
    if (await file.exists() && await file.length() > 0) return file;
    try {
      final response = await Dio().get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          sendTimeout: _loadTimeout,
          receiveTimeout: _loadTimeout,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 300,
        ),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw StateError('empty audio');
      }
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (_) {
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    }
  }

  String _guessExtension(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
    for (final ext in ['.m4a', '.mp3', '.aac', '.wav', '.caf', '.webm', '.ogg']) {
      if (path.contains(ext)) return ext;
    }
    return '.m4a';
  }

  Future<void> _resetPlayer() async {
    _cancelSubs();
    await _player?.dispose();
    _player = null;
  }

  void _listen(AudioPlayer player) {
    _subs.add(
      player.positionStream.listen((position) {
        if (!mounted) return;
        setState(() => _position = position);
      }),
    );
    _subs.add(
      player.playerStateStream.listen((state) {
        if (!mounted) return;
        final completed = state.processingState == ProcessingState.completed;
        setState(() {
          _playing = state.playing && !completed;
          if (state.playing || completed) _loading = false;
          if (completed) _position = Duration.zero;
        });
        if (completed) {
          unawaited(player.seek(Duration.zero));
          unawaited(player.pause());
        }
      }),
    );
    _subs.add(
      player.durationStream.listen((duration) {
        if (!mounted || duration == null) return;
        setState(() => _duration = duration);
      }),
    );
    _subs.add(
      player.playbackEventStream.listen(
        (_) {},
        onError: (Object _, StackTrace __) {
          if (!mounted) return;
          setState(() {
            _playing = false;
            _loading = false;
          });
          AppToast.show(context, 'Impossible de lire cette note vocale.');
        },
      ),
    );
  }

  Future<void> _toggle() async {
    final url = _url;
    if (url == null) return;
    if (_playing || (_player?.playing ?? false)) {
      await _player?.pause();
      if (mounted) setState(() => _playing = false);
      return;
    }
    await _ActiveVoice.activate(this);

    final existing = _player;
    if (existing != null && existing.audioSource != null) {
      if (mounted) setState(() => _playing = true);
      unawaited(existing.play());
      return;
    }

    if (_loading) return;
    setState(() => _loading = true);
    try {
      await _prepareSession();
      await _resetPlayer();
      final player = AudioPlayer();
      _player = player;
      final file = await _cachedFile(url);
      await player.setFilePath(file.path).timeout(_loadTimeout);
      _listen(player);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _playing = true;
      });
      unawaited(player.play());
    } catch (_) {
      await _resetPlayer();
      if (mounted) {
        setState(() {
          _playing = false;
          _loading = false;
        });
        AppToast.show(context, 'Impossible de lire cette note vocale.');
      }
    }
  }

  Future<void> pauseFromOutside() async {
    await _player?.pause();
    if (mounted) setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final mine = _message.senderIsMe;
    final canPlay = _url != null;
    final total = _duration ?? Duration(seconds: _fallbackSeconds);
    final totalMs = total.inMilliseconds <= 0 ? 1 : total.inMilliseconds;
    final progress = (_position.inMilliseconds / totalMs).clamp(0.0, 1.0);
    final remaining = total - _position;
    final fill = mine ? colors.primary : colors.chipBackground;
    final onFill = mine ? colors.onScrim : colors.textPrimary;
    final accent = mine ? colors.onScrim : colors.primary;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.75,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: AppRadius.lgRadius,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        key: ValueKey('thread-voice-${_message.id}'),
                        tooltip: _playing
                            ? 'Mettre en pause'
                            : 'Lire la note vocale',
                        onPressed: canPlay && (!_loading || _playing)
                            ? _toggle
                            : null,
                        color: accent,
                        icon: _loading && !_playing
                            ? SizedBox(
                                width: AppSpacing.lg,
                                height: AppSpacing.lg,
                                child: CircularProgressIndicator(
                                  strokeWidth: AppSpacing.xxs,
                                  color: accent,
                                ),
                              )
                            : Icon(
                                _playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                              ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: AppRadius.pillRadius,
                          child: LinearProgressIndicator(
                            value: canPlay ? progress : 0,
                            minHeight: AppSpacing.xs,
                            backgroundColor: onFill.withValues(alpha: 0.2),
                            color: accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        formatVoiceClock(
                          remaining.inSeconds > 0
                              ? remaining.inSeconds
                              : _fallbackSeconds,
                        ),
                        style: typography.bodySmall.copyWith(color: onFill),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              formatThreadClock(_message.createdAt),
              style: typography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveVoice {
  static _ThreadVoiceTileState? _current;

  static Future<void> activate(_ThreadVoiceTileState next) async {
    final previous = _current;
    _current = next;
    if (previous != null && previous != next) {
      await previous.pauseFromOutside();
    }
  }

  static void release(_ThreadVoiceTileState state) {
    if (_current == state) _current = null;
  }
}
