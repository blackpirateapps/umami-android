import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../core/network/dio_failure_mapper.dart';
import '../../core/security/secure_session_store.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../remote/umami_api_service.dart';

final class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required UmamiApiService apiService,
    required SecureSessionStore sessionStore,
    required DioFailureMapper failureMapper,
  })  : _apiService = apiService,
        _sessionStore = sessionStore,
        _failureMapper = failureMapper;

  final UmamiApiService _apiService;
  final SecureSessionStore _sessionStore;
  final DioFailureMapper _failureMapper;

  @override
  Future<Result<Failure, AuthSession>> authenticate(LoginCommand command) async {
    try {
      final response = await _apiService.login(
        baseUrl: command.baseUrl,
        username: command.username,
        password: command.password,
      );
      final session = AuthSession(
        baseUrl: command.baseUrl,
        token: response.token,
        username: command.username,
        password: command.storeCredentialsForRefresh ? command.password : null,
        createdAt: DateTime.now(),
      );

      await _sessionStore.writeSession(
        session,
        includePassword: command.storeCredentialsForRefresh,
      );

      return Success(session);
    } on Object catch (error, stackTrace) {
      return FailureResult(_failureMapper(error, stackTrace));
    }
  }

  @override
  Future<AuthSession?> currentSession() {
    return _sessionStore.readSession();
  }

  @override
  Future<void> signOut() {
    return _sessionStore.clear();
  }
}
