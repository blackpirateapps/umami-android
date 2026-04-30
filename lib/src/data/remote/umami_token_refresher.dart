import 'package:dio/dio.dart';

import '../../core/config/api_config.dart';
import '../../core/network/auth_interceptor.dart';
import '../../core/network/retry_interceptor.dart';
import '../../core/network/token_refresher.dart';
import '../../core/security/secure_session_store.dart';
import '../dto/auth_dto.dart';

final class UmamiTokenRefresher implements TokenRefresher {
  const UmamiTokenRefresher({
    required Dio dio,
    required SecureSessionStore sessionStore,
  })  : _dio = dio,
        _sessionStore = sessionStore;

  final Dio _dio;
  final SecureSessionStore _sessionStore;

  @override
  Future<String> refreshToken() async {
    final session = await _sessionStore.readSession();
    if (session == null || !session.canRefreshWithoutPrompt) {
      throw StateError('No stored Umami credentials are available.');
    }

    _dio.options.baseUrl = ApiConfig.normalizeBaseUrl(session.baseUrl);
    final response = await _dio.post<Object?>(
      '/api/auth/login',
      data: <String, Object>{
        'username': session.username,
        'password': session.password!,
      },
      options: Options(
        extra: const {
          AuthInterceptor.skipAuthKey: true,
          RetryInterceptor.skipRetryKey: true,
        },
      ),
    );

    final dto = AuthResponseDto.fromJson(_readObject(response.data));
    await _sessionStore.writeSession(
      session.copyWith(
        token: dto.token,
        createdAt: DateTime.now(),
      ),
      includePassword: true,
    );

    return dto.token;
  }

  Map<String, dynamic> _readObject(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw FormatException('Expected JSON object, got ${data.runtimeType}.');
  }
}
