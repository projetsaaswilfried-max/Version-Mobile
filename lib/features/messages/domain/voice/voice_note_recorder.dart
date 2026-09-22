abstract class VoiceNoteRecorder {
  Future<bool> hasPermission();
  Future<void> start({required String path});
  Future<String?> stop();
  Future<void> cancel();
  Stream<double> amplitude({required Duration interval});
  Future<void> dispose();
}

const int kMinVoiceNoteSeconds = 1;
const int kMaxVoiceNoteSeconds = 60;
