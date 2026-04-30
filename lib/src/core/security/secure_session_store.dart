import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/auth_session.dart';
import '../config/api_config.dart';

final class SecureSessionStore {
  const SecureSessionStore(this._storage);

  static const _baseUrlKey = 'umami.baseUrl';
  static const _tokenKey = 'umami.jwt';
  static const _usernameKey = 'umami.username';
  static const _passwordKey = 'umami.password';
  static const _createdAtKey = 'umami.createdAt';

  final FlutterSecureStorage _storage;

  Future<void> writeSession(
    AuthSession session, {
    required bool includePassword,
  }) async {
    await Future.wait([
      _storage.write(
        key: _baseUrlKey,
        value: ApiConfig.normalizeBaseUrl(session.baseUrl),
      ),
      _storage.write(key: _tokenKey, value: session.token),
      _storage.write(key: _usernameKey, value: session.username),
      _storage.write(key: _createdAtKey, value: session.createdAt.toIso8601String()),
      if (includePassword && session.password != null)
        _storage.write(key: _passwordKey, value: session.password)
      else
        _storage.delete(key: _passwordKey),
    ]);
  }

  Future<AuthSession?> readSession() async {
    final values = await Future.wait([
      _storage.read(key: _baseUrlKey),
      _storage.read(key: _tokenKey),
      _storage.read(key: _usernameKey),
      _storage.read(key: _passwordKey),
      _storage.read(key: _createdAtKey),
    ]);

    final baseUrl = values[0];
    final token = values[1];
    final username = values[2];
    final password = values[3];
    final createdAt = values[4];

    if (baseUrl == null || token == null || username == null) {
      return null;
    }

    return AuthSession(
      baseUrl: baseUrl,
      token: token,
      username: username,
      password: password,
      createdAt: createdAt == null
          ? DateTime.now()
          : DateTime.tryParse(createdAt) ?? DateTime.now(),
    );
  }

  Future<String?> readToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<String?> readBaseUrl() async {
    final baseUrl = await _storage.read(key: _baseUrlKey);
    return baseUrl == null ? null : ApiConfig.normalizeBaseUrl(baseUrl);
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _baseUrlKey),
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _usernameKey),
      _storage.delete(key: _passwordKey),
      _storage.delete(key: _createdAtKey),
    ]);
  }
}
