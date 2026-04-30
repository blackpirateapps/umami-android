import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../application/state/dashboard_state.dart';
import '../../domain/entities/analytics_query.dart';
import 'dependencies.dart';

part 'dashboard_controller.g.dart';

@riverpod
class DashboardController extends _$DashboardController {
  late DashboardRequest _request;

  @override
  Future<DashboardState> build(DashboardRequest request) async {
    _request = request;
    return _load(request);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _load(_request));
  }

  Future<DashboardState> _load(DashboardRequest request) async {
    final useCase = ref.watch(getDashboardDataUseCaseProvider);
    final result = await useCase(request);
    return result.when(
      failure: (failure) => throw failure,
      success: (data) => DashboardState(data: data),
    );
  }
}
