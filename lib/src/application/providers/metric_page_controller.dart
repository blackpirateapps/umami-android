import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/analytics_query.dart';
import '../../domain/entities/metric_report.dart';
import 'dependencies.dart';

part 'metric_page_controller.g.dart';

@riverpod
class MetricPageController extends _$MetricPageController {
  late MetricQuery _query;
  bool _loadingNextPage = false;

  @override
  Future<MetricReport> build(MetricQuery query) async {
    _query = query;
    return _load(query);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _load(_query));
  }

  Future<void> loadNextPage() async {
    final current = state.valueOrNull;
    if (_loadingNextPage || current == null || !current.hasMore) {
      return;
    }

    final nextQuery = MetricQuery(
      websiteId: _query.websiteId,
      range: _query.range,
      type: _query.type,
      filters: _query.filters,
      offset: current.offset + current.rows.length,
      limit: _query.limit,
      search: _query.search,
    );

    _loadingNextPage = true;
    try {
      final next = await _load(nextQuery);
      state = AsyncValue.data(
        MetricReport(
          type: current.type,
          rows: [...current.rows, ...next.rows],
          total: next.total,
          offset: current.offset,
          limit: current.limit,
          fetchedAt: next.fetchedAt,
        ),
      );
    } on Object catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    } finally {
      _loadingNextPage = false;
    }
  }

  Future<MetricReport> _load(MetricQuery query) async {
    final useCase = ref.watch(getMetricPageUseCaseProvider);
    final result = await useCase(query);
    return result.when(
      failure: (failure) => throw failure,
      success: (report) => report,
    );
  }
}
