import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../entities/analytics_query.dart';
import '../entities/metric_report.dart';
import '../repositories/analytics_repository.dart';

final class GetMetricPageUseCase {
  const GetMetricPageUseCase(this._repository);

  final AnalyticsRepository _repository;

  Future<Result<Failure, MetricReport>> call(MetricQuery query) {
    return _repository.getMetrics(query);
  }
}
