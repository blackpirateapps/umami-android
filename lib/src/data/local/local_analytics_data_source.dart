import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/entities/analytics_query.dart';
import '../../domain/entities/metric_report.dart';
import '../../domain/entities/session_stats.dart';
import '../../domain/entities/time_series_point.dart';
import '../../domain/entities/website.dart';
import '../mappers/umami_mappers.dart';
import 'app_database.dart';

final class LocalAnalyticsDataSource {
  LocalAnalyticsDataSource({
    required AppDatabase database,
    required WebsiteMapper websiteMapper,
    required StatsMapper statsMapper,
    required MetricMapper metricMapper,
  })  : _database = database,
        _websiteMapper = websiteMapper,
        _statsMapper = statsMapper,
        _metricMapper = metricMapper;

  final AppDatabase _database;
  final WebsiteMapper _websiteMapper;
  final StatsMapper _statsMapper;
  final MetricMapper _metricMapper;

  Stream<List<Website>> watchWebsites() {
    final query = _database.select(_database.cachedWebsites)
      ..orderBy([(table) => OrderingTerm.asc(table.name)]);
    return query.watch().map(
          (rows) => rows.map(_websiteMapper.fromCache).toList(growable: false),
        );
  }

  Future<List<Website>> readWebsites() async {
    final query = _database.select(_database.cachedWebsites)
      ..orderBy([(table) => OrderingTerm.asc(table.name)]);
    final rows = await query.get();
    return rows.map(_websiteMapper.fromCache).toList(growable: false);
  }

  Future<Website?> readWebsite(String websiteId) async {
    final query = _database.select(_database.cachedWebsites)
      ..where((table) => table.id.equals(websiteId));
    final row = await query.getSingleOrNull();
    return row == null ? null : _websiteMapper.fromCache(row);
  }

  Future<void> upsertWebsites(List<Website> websites) async {
    final now = DateTime.now();
    await _database.transaction(() async {
      for (final website in websites) {
        final row = CachedWebsitesCompanion.insert(
          id: website.id,
          name: website.name,
          domain: website.domain,
          shareId: Value(website.shareId),
          createdAt: Value(website.createdAt),
          updatedAt: Value(website.updatedAt),
          isActive: Value(website.isActive),
          cachedAt: now,
        );
        await _database
            .into(_database.cachedWebsites)
            .insertOnConflictUpdate(row);
      }
    });
  }

  Future<SessionStats?> readStats({
    required String websiteId,
    required AnalyticsDateRange range,
  }) async {
    final query = _database.select(_database.cachedStats)
      ..where(
        (table) =>
            table.websiteId.equals(websiteId) &
            table.startAt.equals(range.startAt) &
            table.endAt.equals(range.endAt),
      );
    final row = await query.getSingleOrNull();
    return row == null ? null : _statsMapper.fromCache(row);
  }

  Future<void> upsertStats({
    required String websiteId,
    required AnalyticsDateRange range,
    required SessionStats stats,
  }) {
    return _database.into(_database.cachedStats).insertOnConflictUpdate(
          CachedStatsCompanion.insert(
            websiteId: websiteId,
            startAt: range.startAt,
            endAt: range.endAt,
            visitors: stats.visitors,
            pageviews: stats.pageviews,
            visits: stats.visits,
            bounces: stats.bounces,
            totalTimeSeconds: stats.totalTimeSeconds,
            bounceRate: stats.bounceRate,
            cachedAt: DateTime.now(),
          ),
        );
  }

  Future<List<TimeSeriesPoint>?> readPageviews({
    required String websiteId,
    required AnalyticsDateRange range,
  }) async {
    final query = _database.select(_database.cachedPageviews)
      ..where(
        (table) =>
            table.websiteId.equals(websiteId) &
            table.startAt.equals(range.startAt) &
            table.endAt.equals(range.endAt),
      );
    final row = await query.getSingleOrNull();
    if (row == null) {
      return null;
    }

    final decoded = jsonDecode(row.pointsJson) as List<dynamic>;
    return decoded
        .map((item) {
          final value = item as Map<String, dynamic>;
          return TimeSeriesPoint(
            timestamp: DateTime.parse(value['timestamp'] as String),
            pageviews: value['pageviews'] as int,
            sessions: value['sessions'] as int,
          );
        })
        .toList(growable: false);
  }

  Future<void> upsertPageviews({
    required String websiteId,
    required AnalyticsDateRange range,
    required List<TimeSeriesPoint> points,
  }) {
    final json = jsonEncode(
      points
          .map(
            (point) => <String, Object>{
              'timestamp': point.timestamp.toIso8601String(),
              'pageviews': point.pageviews,
              'sessions': point.sessions,
            },
          )
          .toList(growable: false),
    );

    return _database.into(_database.cachedPageviews).insertOnConflictUpdate(
          CachedPageviewsCompanion.insert(
            websiteId: websiteId,
            startAt: range.startAt,
            endAt: range.endAt,
            pointsJson: json,
            cachedAt: DateTime.now(),
          ),
        );
  }

  Future<MetricReport?> readMetrics(MetricQuery query) async {
    final dbQuery = _database.select(_database.cachedMetrics)
      ..where(
        (table) =>
            table.websiteId.equals(query.websiteId) &
            table.startAt.equals(query.range.startAt) &
            table.endAt.equals(query.range.endAt) &
            table.metricType.equals(query.type.apiName) &
            table.queryKey.equals(query.cacheKey) &
            table.offset.equals(query.offset) &
            table.limit.equals(query.limit),
      );
    final row = await dbQuery.getSingleOrNull();
    if (row == null) {
      return null;
    }

    final decoded = jsonDecode(row.rowsJson) as List<dynamic>;
    return MetricReport(
      type: _metricMapper.metricTypeFromName(row.metricType),
      rows: decoded
          .map((item) {
            final value = item as Map<String, dynamic>;
            return MetricRow(
              value: value['value'] as String,
              count: value['count'] as int,
            );
          })
          .toList(growable: false),
      total: row.total,
      offset: row.offset,
      limit: row.limit,
      fetchedAt: row.cachedAt,
    );
  }

  Future<void> upsertMetrics({
    required MetricQuery query,
    required MetricReport report,
  }) {
    final json = jsonEncode(
      report.rows
          .map(
            (row) => <String, Object>{
              'value': row.value,
              'count': row.count,
            },
          )
          .toList(growable: false),
    );

    return _database.into(_database.cachedMetrics).insertOnConflictUpdate(
          CachedMetricsCompanion.insert(
            websiteId: query.websiteId,
            startAt: query.range.startAt,
            endAt: query.range.endAt,
            metricType: query.type.apiName,
            queryKey: query.cacheKey,
            offset: query.offset,
            limit: query.limit,
            total: report.total,
            rowsJson: json,
            cachedAt: DateTime.now(),
          ),
        );
  }
}
