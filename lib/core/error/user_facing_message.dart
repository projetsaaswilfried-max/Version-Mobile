import 'failure.dart';

String userFacingMessage(Failure failure) {
  final raw = failure.message.trim();
  if (raw.isEmpty || _looksTechnical(raw)) {
    return _defaultFor(failure);
  }
  return raw;
}

String userFacingMessageFromRaw(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty || _looksTechnical(value)) {
    return const UnknownFailure().message;
  }
  return value;
}

String _defaultFor(Failure failure) => switch (failure) {
  NetworkFailure() => const NetworkFailure().message,
  ServerFailure() => const ServerFailure().message,
  UnauthorizedFailure() => const UnauthorizedFailure().message,
  EmailNotConfirmedFailure() => const EmailNotConfirmedFailure().message,
  ValidationFailure() => failure.message.trim().isEmpty
      ? const UnknownFailure().message
      : failure.message,
  CacheFailure() => const CacheFailure().message,
  UnknownFailure() => const UnknownFailure().message,
};

bool _looksTechnical(String raw) {
  if (RegExp(
    r'pgrst\d*|postgrest|supabase|exception|stack.?trace',
    caseSensitive: false,
  ).hasMatch(raw)) {
    return true;
  }
  final lower = raw.toLowerCase();
  final hasFrenchMark = RegExp(r'[éèêëàâùûôîïç]').hasMatch(lower);
  if (hasFrenchMark) return false;
  return RegExp(
    r'\b(failed|error|invalid|jwt|unauthorized)\b',
    caseSensitive: false,
  ).hasMatch(raw);
}
