String formatThreadClock(DateTime date) {
  final local = date.isUtc ? date.toLocal() : date;
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

bool isSameCalendarDay(DateTime a, DateTime b) {
  final left = a.isUtc ? a.toLocal() : a;
  final right = b.isUtc ? b.toLocal() : b;
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

String formatThreadDayLabel(DateTime date, {DateTime? now}) {
  final local = date.isUtc ? date.toLocal() : date;
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final day = DateTime(local.year, local.month, local.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Aujourd\'hui';
  if (diff == 1) return 'Hier';
  final dd = day.day.toString().padLeft(2, '0');
  final mm = day.month.toString().padLeft(2, '0');
  return '$dd/$mm/${day.year}';
}
