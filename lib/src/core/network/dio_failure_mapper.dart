import 'package:dio/dio.dart';

import '../error/failure.dart';

final class DioFailureMapper {
  const DioFailureMapper();

  Failure call(Object error, StackTrace stackTrace) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        return AuthenticationFailure(
          message: 'Authentication failed. Please sign in again.',
          cause: error,
          stackTrace: stackTrace,
        );
      }

      return NetworkFailure(
        message: _networkMessage(error),
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is FormatException || error is TypeError) {
      return ParsingFailure(
        message: 'The server response could not be parsed.',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    return UnknownFailure(
      message: 'Something went wrong.',
      cause: error,
      stackTrace: stackTrace,
    );
  }

  String _networkMessage(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode != null) {
      return 'Umami returned HTTP $statusCode.';
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        'The connection to Umami timed out.',
      DioExceptionType.connectionError => 'Could not reach the Umami server.',
      _ => 'The Umami request failed.',
    };
  }
}
