import 'failure.dart';

/// Return type for usecases/repositories: either a value or a [Failure].
/// Kept as a plain sealed class (Dart 3 pattern matching) instead of a
/// package like dartz, per the "domain is pure Dart, no extra deps" rule.
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}
