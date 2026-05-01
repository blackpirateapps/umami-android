import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../entities/analytics_query.dart';
import '../entities/dashboard_data.dart';
import '../entities/metric_report.dart';
import '../entities/session_report.dart';
import '../entities/session_stats.dart';
import '../entities/time_series_point.dart';
import '../entities/website.dart';

abstract interface class AnalyticsRepository {
  Stream<List<Website>> watchCachedWebsites();

  Future<Result<Failure, List<Website>>> syncWebsites();

  Future<Result<Failure, Website>> getWebsite(String websiteId);

  Future<Result<Failure, SessionStats>> getWebsiteStats({
    required String websiteId,
    required AnalyticsDateRange range,
    AnalyticsFilters filters = const AnalyticsFilters(),
  });

  Future<Result<Failure, List<TimeSeriesPoint>>> getPageviews({
    required String websiteId,
    required AnalyticsDateRange range,
    AnalyticsFilters filters = const AnalyticsFilters(),
  });

  Future<Result<Failure, MetricReport>> getMetrics(MetricQuery query);

  Future<Result<Failure, SessionReport>> getSessions(SessionsQuery query);

  Future<Result<Failure, DashboardData>> getDashboard(DashboardRequest request);
}
