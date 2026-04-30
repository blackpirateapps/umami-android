sealed class Result<F, S> {
  const Result();

  T when<T>({
    required T Function(F failure) failure,
    required T Function(S success) success,
  });

  bool get isSuccess => this is Success<F, S>;
  bool get isFailure => this is FailureResult<F, S>;
}

final class Success<F, S> extends Result<F, S> {
  const Success(this.value);

  final S value;

  @override
  T when<T>({
    required T Function(F failure) failure,
    required T Function(S success) success,
  }) {
    return success(value);
  }
}

final class FailureResult<F, S> extends Result<F, S> {
  const FailureResult(this.value);

  final F value;

  @override
  T when<T>({
    required T Function(F failure) failure,
    required T Function(S success) success,
  }) {
    return failure(value);
  }
}
