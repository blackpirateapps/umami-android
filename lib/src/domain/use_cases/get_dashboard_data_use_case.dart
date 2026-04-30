import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../entities/analytics_query.dart';
import '../entities/dashboard_data.dart';
import '../repositories/analytics_repository.dart';

final class GetDashboardDataUseCase {
  const GetDashboardDataUseCase(this._repository);

  final AnalyticsRepository _repository;

  Future<Result<Failure, DashboardData>> call(DashboardRequest request) {
    return _repository.getDashboard(request);
  }
}
