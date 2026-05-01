import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../entities/analytics_query.dart';
import '../entities/session_report.dart';
import '../repositories/analytics_repository.dart';

final class GetSessionsUseCase {
  const GetSessionsUseCase(this._repository);

  final AnalyticsRepository _repository;

  Future<Result<Failure, SessionReport>> call(SessionsQuery query) {
    return _repository.getSessions(query);
  }
}
