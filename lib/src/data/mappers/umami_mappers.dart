import 'dart:collection';

import '../../core/time/timezone_normalizer.dart';
import '../../domain/entities/analytics_query.dart';
import '../../domain/entities/metric_report.dart';
import '../../domain/entities/session_report.dart';
import '../../domain/entities/session_stats.dart';
import '../../domain/entities/time_series_point.dart';
import '../../domain/entities/website.dart';
import '../dto/metric_dto.dart';
import '../dto/pageviews_dto.dart';
import '../dto/session_dto.dart';
import '../dto/stats_dto.dart';
import '../dto/website_dto.dart';
import '../local/app_database.dart';

final class WebsiteMapper {
  const WebsiteMapper();

  Website fromDto(WebsiteDto dto) {
    return Website(
      id: dto.id,
      name: dto.name,
      domain: dto.domain,
      shareId: dto.shareId,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      isActive: dto.isActive,
    );
  }

  Website fromCache(CachedWebsite row) {
    return Website(
      id: row.id,
      name: row.name,
      domain: row.domain,
      shareId: row.shareId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isActive: row.isActive,
    );
  }
}

final class StatsMapper {
  const StatsMapper();

  SessionStats fromDto(StatsResponseDto dto) {
    final visitors = _toInt(dto.visitors?.value);
    final pageviews = _toInt(dto.pageviews?.value);
    final visits = _toInt(dto.visits?.value);
    final bounces = _toInt(dto.bounces?.value);
    final totalTime = _toInt(dto.totalTime?.value);
    final bounceRate = visits == 0 ? 0.0 : bounces / visits;

    return SessionStats(
      visitors: visitors,
      pageviews: pageviews,
      visits: visits,
      bounces: bounces,
      totalTimeSeconds: totalTime,
      bounceRate: bounceRate,
      previousVisitors: _toNullableInt(
        dto.visitors?.prev ?? dto.comparison?.visitors,
      ),
      previousPageviews: _toNullableInt(
        dto.pageviews?.prev ?? dto.comparison?.pageviews,
      ),
      previousVisits: _toNullableInt(
        dto.visits?.prev ?? dto.comparison?.visits,
      ),
      previousBounces: _toNullableInt(
        dto.bounces?.prev ?? dto.comparison?.bounces,
      ),
      previousTotalTimeSeconds: _toNullableInt(
        dto.totalTime?.prev ?? dto.comparison?.totalTime,
      ),
    );
  }

  SessionStats fromCache(CachedStat row) {
    return SessionStats(
      visitors: row.visitors,
      pageviews: row.pageviews,
      visits: row.visits,
      bounces: row.bounces,
      totalTimeSeconds: row.totalTimeSeconds,
      bounceRate: row.bounceRate,
    );
  }

  int _toInt(num? value) => value?.round() ?? 0;

  int? _toNullableInt(num? value) => value?.round();
}

final class PageviewsMapper {
  const PageviewsMapper(this._timezoneNormalizer);

  final TimezoneNormalizer _timezoneNormalizer;

  List<TimeSeriesPoint> fromDto(
    PageviewsResponseDto dto, {
    int? timezoneOffsetMinutes,
  }) {
    final points = SplayTreeMap<DateTime, _PointAccumulator>();

    for (final pageview in dto.pageviews) {
      final timestamp = _timezoneNormalizer.fromApiTimestamp(
        pageview.timestamp,
        timezoneOffsetMinutes: timezoneOffsetMinutes,
      );
      points.putIfAbsent(timestamp, _PointAccumulator.new).pageviews =
          pageview.value;
    }

    for (final session in dto.sessions) {
      final timestamp = _timezoneNormalizer.fromApiTimestamp(
        session.timestamp,
        timezoneOffsetMinutes: timezoneOffsetMinutes,
      );
      points.putIfAbsent(timestamp, _PointAccumulator.new).sessions =
          session.value;
    }

    return points.entries
        .map(
          (entry) => TimeSeriesPoint(
            timestamp: entry.key,
            pageviews: entry.value.pageviews,
            sessions: entry.value.sessions,
          ),
        )
        .toList(growable: false);
  }
}

final class MetricMapper {
  const MetricMapper();

  MetricReport fromDto(MetricResponseDto dto) {
    return MetricReport(
      type: dto.type,
      rows: dto.rows
          .map(
            (row) => MetricRow(
              value: row.value,
              count: row.count,
            ),
          )
          .toList(growable: false),
      total: dto.total,
      offset: dto.offset,
      limit: dto.limit,
      fetchedAt: DateTime.now(),
    );
  }

  MetricType metricTypeFromName(String value) {
    return MetricType.values.firstWhere(
      (type) => type.apiName == value,
      orElse: () => MetricType.path,
    );
  }
}

final class SessionMapper {
  const SessionMapper();

  SessionReport fromDto(SessionsResponseDto dto) {
    return SessionReport(
      rows: dto.data
          .map(
            (row) => WebsiteSession(
              id: row.id,
              websiteId: row.websiteId,
              hostname: row.hostname,
              browser: row.browser,
              os: row.os,
              device: row.device,
              screen: row.screen,
              language: row.language,
              country: row.country,
              region: row.region,
              city: row.city,
              visits: row.visits,
              views: row.views,
              events: row.events,
              firstAt: row.firstAt,
              lastAt: row.lastAt,
              createdAt: row.createdAt,
            ),
          )
          .toList(growable: false),
      count: dto.count,
      page: dto.page,
      pageSize: dto.pageSize,
      fetchedAt: DateTime.now(),
    );
  }
}

final class _PointAccumulator {
  int pageviews = 0;
  int sessions = 0;
}
