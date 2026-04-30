import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

final class AuthenticateUserUseCase {
  const AuthenticateUserUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<Failure, AuthSession>> call(LoginCommand command) {
    return _repository.authenticate(command);
  }
}
