String formatVoiceClock(int totalSeconds) {
  final safe = totalSeconds < 0 ? 0 : totalSeconds;
  final minutes = safe ~/ 60;
  final seconds = safe % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
