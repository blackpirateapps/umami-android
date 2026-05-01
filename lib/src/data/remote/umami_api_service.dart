import 'package:dio/dio.dart';

import '../../core/config/api_config.dart';
import '../../core/network/auth_interceptor.dart';
import '../../core/network/retry_interceptor.dart';
import '../../core/time/timezone_normalizer.dart';
import '../../domain/entities/analytics_query.dart';
import '../dto/auth_dto.dart';
import '../dto/metric_dto.dart';
import '../dto/pageviews_dto.dart';
import '../dto/session_dto.dart';
import '../dto/stats_dto.dart';
import '../dto/website_dto.dart';

final class UmamiApiService {
  const UmamiApiService({
    required Dio dio,
    required TimezoneNormalizer timezoneNormalizer,
  })  : _dio = dio,
        _timezoneNormalizer = timezoneNormalizer;

  final Dio _dio;
  final TimezoneNormalizer _timezoneNormalizer;

  Future<AuthResponseDto> login({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    _dio.options.baseUrl = ApiConfig.normalizeBaseUrl(baseUrl);
    final response = await _dio.post<Object?>(
      '/api/auth/login',
      data: <String, Object>{
        'username': username,
        'password': password,
      },
      options: Options(
        extra: const {
          AuthInterceptor.skipAuthKey: true,
          RetryInterceptor.skipRetryKey: true,
        },
      ),
    );

    return AuthResponseDto.fromJson(_readObject(response.data));
  }

  Future<List<WebsiteDto>> getWebsites() async {
    final response = await _dio.get<Object?>('/api/websites');
    return _readList(response.data)
        .map((item) => WebsiteDto.fromJson(_readObject(item)))
        .toList(growable: false);
  }

  Future<StatsResponseDto> getStats({
    required String websiteId,
    required AnalyticsDateRange range,
    AnalyticsFilters filters = const AnalyticsFilters(),
  }) async {
    final response = await _dio.get<Object?>(
      '/api/websites/$websiteId/stats',
      queryParameters: <String, Object?>{
        ..._baseRangeQuery(range),
        ..._filterQuery(filters),
      },
    );
    return StatsResponseDto.fromJson(_readObject(response.data));
  }

  Future<PageviewsResponseDto> getPageviews({
    required String websiteId,
    required AnalyticsDateRange range,
    AnalyticsFilters filters = const AnalyticsFilters(),
  }) async {
    final response = await _dio.get<Object?>(
      '/api/websites/$websiteId/pageviews',
      queryParameters: <String, Object?>{
        ..._seriesRangeQuery(range),
        ..._filterQuery(filters),
      },
    );
    return PageviewsResponseDto.fromJson(_readObject(response.data));
  }

  Future<MetricResponseDto> getMetrics(MetricQuery query) async {
    final response = await _dio.get<Object?>(
      '/api/websites/${query.websiteId}/metrics',
      queryParameters: <String, Object?>{
        ..._baseRangeQuery(query.range),
        ..._filterQuery(query.filters),
        'type': query.type.apiName,
        'offset': query.offset,
        'limit': query.limit,
        if (query.search != null && query.search!.trim().isNotEmpty)
          'search': query.search!.trim(),
      },
    );

    final data = response.data;
    final rows = _readList(data);
    final total = data is Map
        ? ((data['total'] as num?)?.round() ?? rows.length)
        : rows.length;

    return MetricResponseDto(
      type: query.type,
      rows: rows
          .map((item) => MetricDto.fromJson(_readObject(item)))
          .toList(growable: false),
      total: total,
      offset: query.offset,
      limit: query.limit,
    );
  }

  Future<SessionsResponseDto> getSessions(SessionsQuery query) async {
    final response = await _dio.get<Object?>(
      '/api/websites/${query.websiteId}/sessions',
      queryParameters: <String, Object?>{
        ..._baseRangeQuery(query.range),
        ..._filterQuery(query.filters),
        'page': query.page,
        'pageSize': query.pageSize,
        if (query.search != null && query.search!.trim().isNotEmpty)
          'search': query.search!.trim(),
      },
    );

    final data = response.data;
    if (data is Map) {
      return SessionsResponseDto.fromJson(_readObject(data));
    }

    final rows = _readList(data)
        .map((item) => SessionDto.fromJson(_readObject(item)))
        .toList(growable: false);
    return SessionsResponseDto(
      data: rows,
      count: rows.length,
      page: query.page,
      pageSize: query.pageSize,
    );
  }

  Map<String, Object?> _baseRangeQuery(AnalyticsDateRange range) {
    return <String, Object?>{
      'startAt': _timezoneNormalizer.toEpochMilliseconds(range.startAt),
      'endAt': _timezoneNormalizer.toEpochMilliseconds(range.endAt),
    };
  }

  Map<String, Object?> _seriesRangeQuery(AnalyticsDateRange range) {
    return <String, Object?>{
      ..._baseRangeQuery(range),
      'unit': range.unit.apiName,
      'timezone': range.timezone,
    };
  }

  Map<String, Object?> _filterQuery(AnalyticsFilters filters) {
    return <String, Object?>{
      if (filters.url != null) 'path': filters.url,
      if (filters.referrer != null) 'referrer': filters.referrer,
      if (filters.browser != null) 'browser': filters.browser,
      if (filters.os != null) 'os': filters.os,
      if (filters.device != null) 'device': filters.device,
      if (filters.country != null) 'country': filters.country,
    };
  }

  List<dynamic> _readList(Object? data) {
    if (data is List) {
      return data;
    }

    if (data is Map) {
      final envelope = data['data'] ?? data['items'] ?? data['results'];
      if (envelope is List) {
        return envelope;
      }
    }

    return const <dynamic>[];
  }

  Map<String, dynamic> _readObject(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw FormatException('Expected JSON object, got ${data.runtimeType}.');
  }
}
