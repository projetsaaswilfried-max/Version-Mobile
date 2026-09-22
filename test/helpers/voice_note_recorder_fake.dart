import 'dart:async';

import 'package:agapeo/features/messages/domain/voice/voice_note_recorder.dart';

class FakeVoiceNoteRecorder implements VoiceNoteRecorder {
  FakeVoiceNoteRecorder({this.hasPermissionResult = true, this.stopPath});

  bool hasPermissionResult;
  String? stopPath;
  var startCalls = 0;
  var stopCalls = 0;
  var cancelCalls = 0;
  var disposeCalls = 0;
  String? lastStartPath;
  final _amplitude = StreamController<double>.broadcast();

  void emitAmplitude(double value) {
    if (!_amplitude.isClosed) _amplitude.add(value);
  }

  @override
  Future<bool> hasPermission() async => hasPermissionResult;

  @override
  Future<void> start({required String path}) async {
    startCalls++;
    lastStartPath = path;
  }

  @override
  Future<String?> stop() async {
    stopCalls++;
    return stopPath ?? lastStartPath;
  }

  @override
  Future<void> cancel() async {
    cancelCalls++;
  }

  @override
  Stream<double> amplitude({required Duration interval}) => _amplitude.stream;

  @override
  Future<void> dispose() async {
    disposeCalls++;
    await _amplitude.close();
  }
}
