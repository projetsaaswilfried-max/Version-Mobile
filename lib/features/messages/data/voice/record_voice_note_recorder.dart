import 'package:record/record.dart';

import '../../domain/voice/voice_note_recorder.dart';

class RecordVoiceNoteRecorder implements VoiceNoteRecorder {
  RecordVoiceNoteRecorder({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start({required String path}) {
    return _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: path,
    );
  }

  @override
  Future<String?> stop() => _recorder.stop();

  @override
  Future<void> cancel() => _recorder.cancel();

  @override
  Stream<double> amplitude({required Duration interval}) {
    return _recorder.onAmplitudeChanged(interval).map(_normalize);
  }

  @override
  Future<void> dispose() => _recorder.dispose();

  static double _normalize(Amplitude amplitude) {
    return ((amplitude.current + 45) / 45).clamp(0.08, 1.0);
  }
}
