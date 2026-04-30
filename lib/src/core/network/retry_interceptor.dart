import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

final class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required Dio dio,
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 250),
  }) : _dio = dio;

  static const skipRetryKey = 'skipRetry';
  static const _attemptKey = 'retryAttempt';

  final Dio _dio;
  final int maxRetries;
  final Duration baseDelay;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final attempt = (request.extra[_attemptKey] as int?) ?? 0;

    if (request.extra[skipRetryKey] == true ||
        attempt >= maxRetries ||
        !_isRetryable(err)) {
      handler.next(err);
      return;
    }

    final nextAttempt = attempt + 1;
    request.extra[_attemptKey] = nextAttempt;
    await Future<void>.delayed(baseDelay * (1 << attempt));

    try {
      final response = await _dio.fetch<Object?>(request);
      handler.resolve(response);
    } on DioException catch (error) {
      handler.next(error);
    }
  }

  bool _isRetryable(DioException err) {
    if (err.error is SocketException || err.error is TimeoutException) {
      return true;
    }

    return switch (err.response?.statusCode) {
      408 || 429 || 500 || 502 || 503 || 504 => true,
      _ => false,
    };
  }
}
