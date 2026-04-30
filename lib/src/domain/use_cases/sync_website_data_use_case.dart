import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../entities/website.dart';
import '../repositories/analytics_repository.dart';

final class SyncWebsiteDataUseCase {
  const SyncWebsiteDataUseCase(this._repository);

  final AnalyticsRepository _repository;

  Stream<List<Website>> watchCachedWebsites() {
    return _repository.watchCachedWebsites();
  }

  Future<Result<Failure, List<Website>>> call() {
    return _repository.syncWebsites();
  }
}
