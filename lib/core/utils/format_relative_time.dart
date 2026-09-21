/// Libellé relatif en français (fil, notifications).
String formatRelativeTime(DateTime date, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final local = date.isUtc ? date.toLocal() : date;
  final diff = reference.difference(local);
  if (diff.isNegative) {
    return _calendarDate(local);
  }
  if (diff.inSeconds < 60) return 'À l\'instant';
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
  return _calendarDate(local);
}

String _calendarDate(DateTime local) {
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/${local.year}';
}
