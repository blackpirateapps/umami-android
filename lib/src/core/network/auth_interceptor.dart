import 'package:dio/dio.dart';

import '../security/secure_session_store.dart';
import 'token_refresher.dart';

final class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required Dio dio,
    required SecureSessionStore sessionStore,
    required TokenRefresher tokenRefresher,
  })  : _dio = dio,
        _sessionStore = sessionStore,
        _tokenRefresher = tokenRefresher;

  static const skipAuthKey = 'skipAuth';
  static const authRetriedKey = 'authRetried';

  final Dio _dio;
  final SecureSessionStore _sessionStore;
  final TokenRefresher _tokenRefresher;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuthKey] == true) {
      handler.next(options);
      return;
    }

    if (options.baseUrl.isEmpty) {
      final baseUrl = await _sessionStore.readBaseUrl();
      if (baseUrl != null) {
        options.baseUrl = baseUrl;
      }
    }

    final token = await _sessionStore.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final request = err.requestOptions;
    final shouldRefresh = statusCode == 401 &&
        request.extra[skipAuthKey] != true &&
        request.extra[authRetriedKey] != true;

    if (!shouldRefresh) {
      handler.next(err);
      return;
    }

    try {
      final token = await _tokenRefresher.refreshToken();
      request.extra[authRetriedKey] = true;
      request.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.fetch<Object?>(request);
      handler.resolve(response);
    } on Object {
      handler.next(err);
    }
  }
}
