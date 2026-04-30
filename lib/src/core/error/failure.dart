sealed class Failure implements Exception {
  const Failure({
    required this.message,
    this.cause,
    this.stackTrace,
  });

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType: $message';
}

final class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}

final class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}

final class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}

final class ParsingFailure extends Failure {
  const ParsingFailure({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}

final class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}
