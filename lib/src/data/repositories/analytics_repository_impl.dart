import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../core/network/dio_failure_mapper.dart';
import '../../domain/entities/analytics_query.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/entities/metric_report.dart';
import '../../domain/entities/session_report.dart';
import '../../domain/entities/session_stats.dart';
import '../../domain/entities/time_series_point.dart';
import '../../domain/entities/website.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../local/local_analytics_data_source.dart';
import '../mappers/umami_mappers.dart';
import '../remote/umami_api_service.dart';

final class AnalyticsRepositoryImpl implements AnalyticsRepository {
  const AnalyticsRepositoryImpl({
    required UmamiApiService apiService,
    required LocalAnalyticsDataSource localDataSource,
    required WebsiteMapper websiteMapper,
    required StatsMapper statsMapper,
    required PageviewsMapper pageviewsMapper,
    required MetricMapper metricMapper,
    required SessionMapper sessionMapper,
    required DioFailureMapper failureMapper,
  })  : _apiService = apiService,
        _localDataSource = localDataSource,
        _websiteMapper = websiteMapper,
        _statsMapper = statsMapper,
        _pageviewsMapper = pageviewsMapper,
        _metricMapper = metricMapper,
        _sessionMapper = sessionMapper,
        _failureMapper = failureMapper;

  final UmamiApiService _apiService;
  final LocalAnalyticsDataSource _localDataSource;
  final WebsiteMapper _websiteMapper;
  final StatsMapper _statsMapper;
  final PageviewsMapper _pageviewsMapper;
  final MetricMapper _metricMapper;
  final SessionMapper _sessionMapper;
  final DioFailureMapper _failureMapper;

  @override
  Stream<List<Website>> watchCachedWebsites() {
    return _localDataSource.watchWebsites();
  }

  @override
  Future<Result<Failure, List<Website>>> syncWebsites() async {
    try {
      final dtos = await _apiService.getWebsites();
      final websites =
          dtos.map(_websiteMapper.fromDto).toList(growable: false);
      await _localDataSource.upsertWebsites(websites);
      return Success(websites);
    } on Object catch (error, stackTrace) {
      final cached = await _localDataSource.readWebsites();
      if (cached.isNotEmpty) {
        return Success(cached);
      }

      return FailureResult(_failureMapper(error, stackTrace));
    }
  }

  @override
  Future<Result<Failure, Website>> getWebsite(String websiteId) async {
    final cached = await _localDataSource.readWebsite(websiteId);
    if (cached != null) {
      return Success(cached);
    }

    final synced = await syncWebsites();
    return synced.when(
      failure: FailureResult.new,
      success: (websites) {
        final matches = websites.where((website) => website.id == websiteId);
        if (matches.isEmpty) {
          return const FailureResult(
            CacheFailure(message: 'Website was not found in local cache.'),
          );
        }
        return Success(matches.first);
      },
    );
  }

  @override
  Future<Result<Failure, SessionStats>> getWebsiteStats({
    required String websiteId,
    required AnalyticsDateRange range,
    AnalyticsFilters filters = const AnalyticsFilters(),
  }) async {
    final cached = filters.isEmpty
        ? await _localDataSource.readStats(
            websiteId: websiteId,
            range: range,
          )
        : null;

    try {
      final dto = await _apiService.getStats(
        websiteId: websiteId,
        range: range,
        filters: filters,
      );
      final stats = _statsMapper.fromDto(dto);
      if (filters.isEmpty) {
        await _localDataSource.upsertStats(
          websiteId: websiteId,
          range: range,
          stats: stats,
        );
      }
      return Success(stats);
    } on Object catch (error, stackTrace) {
      if (cached != null) {
        return Success(cached);
      }

      return FailureResult(_failureMapper(error, stackTrace));
    }
  }

  @override
  Future<Result<Failure, List<TimeSeriesPoint>>> getPageviews({
    required String websiteId,
    required AnalyticsDateRange range,
    AnalyticsFilters filters = const AnalyticsFilters(),
  }) async {
    final cached = filters.isEmpty
        ? await _localDataSource.readPageviews(
            websiteId: websiteId,
            range: range,
          )
        : null;

    try {
      final dto = await _apiService.getPageviews(
        websiteId: websiteId,
        range: range,
        filters: filters,
      );
      final points = _pageviewsMapper.fromDto(
        dto,
        timezoneOffsetMinutes: range.timezoneOffsetMinutes,
      );
      if (filters.isEmpty) {
        await _localDataSource.upsertPageviews(
          websiteId: websiteId,
          range: range,
          points: points,
        );
      }
      return Success(points);
    } on Object catch (error, stackTrace) {
      if (cached != null) {
        return Success(cached);
      }

      return FailureResult(_failureMapper(error, stackTrace));
    }
  }

  @override
  Future<Result<Failure, MetricReport>> getMetrics(MetricQuery query) async {
    final cached = await _localDataSource.readMetrics(query);

    try {
      final dto = await _apiService.getMetrics(query);
      final report = _metricMapper.fromDto(dto);
      await _localDataSource.upsertMetrics(
        query: query,
        report: report,
      );
      return Success(report);
    } on Object catch (error, stackTrace) {
      if (cached != null) {
        return Success(cached);
      }

      return FailureResult(_failureMapper(error, stackTrace));
    }
  }

  @override
  Future<Result<Failure, SessionReport>> getSessions(SessionsQuery query) async {
    try {
      final dto = await _apiService.getSessions(query);
      return Success(_sessionMapper.fromDto(dto));
    } on Object catch (error, stackTrace) {
      return FailureResult(_failureMapper(error, stackTrace));
    }
  }

  @override
  Future<Result<Failure, DashboardData>> getDashboard(
    DashboardRequest request,
  ) async {
    final websiteFuture = getWebsite(request.websiteId);
    final statsFuture = getWebsiteStats(
      websiteId: request.websiteId,
      range: request.range,
      filters: request.filters,
    );
    final pageviewsFuture = getPageviews(
      websiteId: request.websiteId,
      range: request.range,
      filters: request.filters,
    );
    final topPagesFuture = getMetrics(
      MetricQuery(
        websiteId: request.websiteId,
        range: request.range,
        type: MetricType.path,
        filters: request.filters,
        limit: 10,
      ),
    );
    final referrersFuture = getMetrics(
      MetricQuery(
        websiteId: request.websiteId,
        range: request.range,
        type: MetricType.referrer,
        filters: request.filters,
        limit: 10,
      ),
    );
    final browsersFuture = getMetrics(
      MetricQuery(
        websiteId: request.websiteId,
        range: request.range,
        type: MetricType.browser,
        filters: request.filters,
        limit: 10,
      ),
    );
    final operatingSystemsFuture = getMetrics(
      MetricQuery(
        websiteId: request.websiteId,
        range: request.range,
        type: MetricType.os,
        filters: request.filters,
        limit: 10,
      ),
    );
    final devicesFuture = getMetrics(
      MetricQuery(
        websiteId: request.websiteId,
        range: request.range,
        type: MetricType.device,
        filters: request.filters,
        limit: 10,
      ),
    );
    final countriesFuture = getMetrics(
      MetricQuery(
        websiteId: request.websiteId,
        range: request.range,
        type: MetricType.country,
        filters: request.filters,
        limit: 250,
      ),
    );

    try {
      await Future.wait([
        websiteFuture,
        statsFuture,
        pageviewsFuture,
        topPagesFuture,
        referrersFuture,
        browsersFuture,
        operatingSystemsFuture,
        devicesFuture,
        countriesFuture,
      ]);

      return Success(
        DashboardData(
          website: _value(await websiteFuture),
          stats: _value(await statsFuture),
          pageviews: _value(await pageviewsFuture),
          topPages: _value(await topPagesFuture),
          referrers: _value(await referrersFuture),
          browsers: _value(await browsersFuture),
          operatingSystems: _value(await operatingSystemsFuture),
          devices: _value(await devicesFuture),
          countries: _value(await countriesFuture),
          fetchedAt: DateTime.now(),
        ),
      );
    } on Failure catch (failure) {
      return FailureResult(failure);
    }
  }

  T _value<T>(Result<Failure, T> result) {
    return result.when(
      failure: (failure) => throw failure,
      success: (value) => value,
    );
  }
}
