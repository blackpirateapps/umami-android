import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/website.dart';
import 'dependencies.dart';

part 'websites_controller.g.dart';

@riverpod
class WebsitesController extends _$WebsitesController {
  @override
  Future<List<Website>> build() async {
    final useCase = ref.watch(syncWebsiteDataUseCaseProvider);
    final result = await useCase();
    return result.when(
      failure: (failure) => throw failure,
      success: (websites) => websites,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}
