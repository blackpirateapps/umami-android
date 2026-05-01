import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/analytics_query.dart';
import '../../domain/entities/session_report.dart';
import 'dependencies.dart';

part 'sessions_controller.g.dart';

@riverpod
class SessionsController extends _$SessionsController {
  late SessionsQuery _query;
  bool _loadingNextPage = false;

  @override
  Future<SessionReport> build(SessionsQuery query) async {
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

    _loadingNextPage = true;
    try {
      final next = await _load(
        SessionsQuery(
          websiteId: _query.websiteId,
          range: _query.range,
          filters: _query.filters,
          page: current.page + 1,
          pageSize: _query.pageSize,
          search: _query.search,
        ),
      );
      state = AsyncValue.data(
        SessionReport(
          rows: [...current.rows, ...next.rows],
          count: next.count,
          page: next.page,
          pageSize: current.pageSize,
          fetchedAt: next.fetchedAt,
        ),
      );
    } on Object catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    } finally {
      _loadingNextPage = false;
    }
  }

  Future<SessionReport> _load(SessionsQuery query) async {
    final useCase = ref.watch(getSessionsUseCaseProvider);
    final result = await useCase(query);
    return result.when(
      failure: (failure) => throw failure,
      success: (report) => report,
    );
  }
}
