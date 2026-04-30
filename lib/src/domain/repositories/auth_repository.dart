import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../entities/auth_session.dart';

abstract interface class AuthRepository {
  Future<Result<Failure, AuthSession>> authenticate(LoginCommand command);

  Future<AuthSession?> currentSession();

  Future<void> signOut();
}
