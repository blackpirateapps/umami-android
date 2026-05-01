import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../entities/analytics_query.dart';
import '../entities/session_stats.dart';
import '../repositories/analytics_repository.dart';

final class GetWebsiteStatsUseCase {
  const GetWebsiteStatsUseCase(this._repository);

  final AnalyticsRepository _repository;

  Future<Result<Failure, SessionStats>> call({
    required String websiteId,
    required AnalyticsDateRange range,
    AnalyticsFilters filters = const AnalyticsFilters(),
  }) {
    return _repository.getWebsiteStats(
      websiteId: websiteId,
      range: range,
      filters: filters,
    );
  }
}
