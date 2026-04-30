import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/analytics_query.dart';
import '../../domain/entities/metric_report.dart';
import 'dependencies.dart';

part 'metric_page_controller.g.dart';

@riverpod
class MetricPageController extends _$MetricPageController {
  late MetricQuery _query;

  @override
  Future<MetricReport> build(MetricQuery query) async {
    _query = query;
    return _load(query);
  }

  Future<void> loadNextPage() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) {
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

    state = await AsyncValue.guard(() async {
      final next = await _load(nextQuery);
      return MetricReport(
        type: current.type,
        rows: [...current.rows, ...next.rows],
        total: next.total,
        offset: current.offset,
        limit: current.limit,
        fetchedAt: next.fetchedAt,
      );
    });
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
