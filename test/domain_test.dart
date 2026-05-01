import 'package:flutter_test/flutter_test.dart';
import 'package:umami_android/src/domain/entities/analytics_date_range_preset.dart';
import 'package:umami_android/src/domain/entities/analytics_query.dart';
import 'package:umami_android/src/domain/entities/country_traffic.dart';
import 'package:umami_android/src/domain/entities/metric_report.dart';
import 'package:umami_android/src/domain/entities/session_stats.dart';

void main() {
  test('last7Days creates an inclusive seven day range', () {
    final range = AnalyticsDateRange.last7Days(
      now: DateTime(2026, 4, 30, 10),
    );

    expect(range.startAt, DateTime(2026, 4, 24));
    expect(range.endAt, DateTime(2026, 4, 30, 23, 59, 59, 999));
    expect(range.unit, TimeUnit.day);
  });

  group('AnalyticsDateRangeSelection', () {
    test('last 24 hours uses hourly buckets', () {
      final range = const AnalyticsDateRangeSelection.preset(
        AnalyticsDateRangePreset.last24Hours,
      ).resolve(now: DateTime(2026, 4, 30, 10, 34));

      expect(range.startAt, DateTime(2026, 4, 29, 11));
      expect(range.endAt, DateTime(2026, 4, 30, 10, 59, 59, 999));
      expect(range.unit, TimeUnit.hour);
      expect(range.timezone, 'UTC');
    });

    test('this week starts on Monday and uses daily buckets', () {
      final range = const AnalyticsDateRangeSelection.preset(
        AnalyticsDateRangePreset.thisWeek,
      ).resolve(now: DateTime(2026, 4, 30, 10));

      expect(range.startAt, DateTime(2026, 4, 27));
      expect(range.endAt, DateTime(2026, 4, 30, 23, 59, 59, 999));
      expect(range.unit, TimeUnit.day);
    });

    test('multi-month presets use monthly buckets', () {
      final range = const AnalyticsDateRangeSelection.preset(
        AnalyticsDateRangePreset.last6Months,
      ).resolve(now: DateTime(2026, 4, 30, 10));

      expect(range.startAt, DateTime(2025, 11));
      expect(range.endAt, DateTime(2026, 4, 30, 23, 59, 59, 999));
      expect(range.unit, TimeUnit.month);
    });

    test('all time starts at the website creation date when available', () {
      final range = const AnalyticsDateRangeSelection.preset(
        AnalyticsDateRangePreset.allTime,
      ).resolve(
        now: DateTime(2026, 4, 30, 10),
        allTimeStartAt: DateTime(2024, 6, 3, 14),
      );

      expect(range.startAt, DateTime(2024, 6, 3));
      expect(range.unit, TimeUnit.month);
    });

    test('custom ranges normalize order and choose a sensible unit', () {
      final range = AnalyticsDateRangeSelection.custom(
        startAt: DateTime(2026, 5, 10),
        endAt: DateTime(2026, 4, 1),
      ).resolve(now: DateTime(2026, 5, 10, 12));

      expect(range.startAt, DateTime(2026, 4));
      expect(range.endAt, DateTime(2026, 5, 10, 23, 59, 59, 999));
      expect(range.unit, TimeUnit.day);
    });

    test('custom ranges use monthly buckets for long spans', () {
      final range = AnalyticsDateRangeSelection.custom(
        startAt: DateTime(2025, 1, 1),
        endAt: DateTime(2026, 4, 30),
      ).resolve(now: DateTime(2026, 4, 30, 10));

      expect(range.unit, TimeUnit.month);
    });

    test('date range changes produce distinct dashboard requests', () {
      final websiteId = 'site-id';
      final last7 = const AnalyticsDateRangeSelection.preset(
        AnalyticsDateRangePreset.last7Days,
      ).resolve(now: DateTime(2026, 4, 30, 10));
      final last30 = const AnalyticsDateRangeSelection.preset(
        AnalyticsDateRangePreset.last30Days,
      ).resolve(now: DateTime(2026, 4, 30, 10));

      expect(
        DashboardRequest(websiteId: websiteId, range: last7),
        isNot(DashboardRequest(websiteId: websiteId, range: last30)),
      );
    });

    test('filter changes produce distinct dashboard requests', () {
      final websiteId = 'site-id';
      final range = const AnalyticsDateRangeSelection.preset(
        AnalyticsDateRangePreset.last7Days,
      ).resolve(now: DateTime(2026, 4, 30, 10));

      expect(
        DashboardRequest(websiteId: websiteId, range: range),
        isNot(
          DashboardRequest(
            websiteId: websiteId,
            range: range,
            filters: const AnalyticsFilters(browser: 'Chrome'),
          ),
        ),
      );
    });
  });

  group('SessionStats comparisons', () {
    test('calculates previous-period percentage changes', () {
      const stats = SessionStats(
        visitors: 150,
        pageviews: 250,
        visits: 200,
        bounces: 50,
        totalTimeSeconds: 600,
        bounceRate: 0.25,
        previousVisitors: 100,
        previousPageviews: 200,
        previousVisits: 100,
        previousBounces: 40,
        previousTotalTimeSeconds: 200,
      );

      expect(stats.visitorsChange, 0.5);
      expect(stats.pageviewsChange, 0.25);
      expect(stats.averageVisitSeconds, 3);
      expect(stats.averageVisitSecondsChange, 0.5);
      expect(stats.bounceRateChange, closeTo(-0.375, 0.001));
    });
  });

  group('Metric pagination', () {
    test('nextPage preserves the metric type, website, and date range', () {
      final range = const AnalyticsDateRangeSelection.preset(
        AnalyticsDateRangePreset.last30Days,
      ).resolve(now: DateTime(2026, 4, 30, 10));
      final query = MetricQuery(
        websiteId: 'site-id',
        range: range,
        type: MetricType.referrer,
        limit: 50,
      );

      final next = query.nextPage();

      expect(next.websiteId, query.websiteId);
      expect(next.range, query.range);
      expect(next.type, MetricType.referrer);
      expect(next.offset, 50);
      expect(next.limit, 50);
    });
  });

  group('CountryTrafficScale', () {
    test('normalizes ISO alpha-2 codes for vector map color keys', () {
      expect(CountryTrafficScale.mapColorKey('US'), 'uS');
      expect(CountryTrafficScale.mapColorKey('in'), 'iN');
      expect(CountryTrafficScale.mapColorKey('unknown'), isNull);
      expect(CountryTrafficScale.mapColorKey('1A'), isNull);
    });

    test('uses square-root scaling with a visible minimum', () {
      expect(
        CountryTrafficScale.intensity(count: 25, maxCount: 100),
        closeTo(0.5, 0.001),
      );
      expect(
        CountryTrafficScale.intensity(count: 1, maxCount: 10000),
        0.18,
      );
      expect(
        CountryTrafficScale.intensity(count: 0, maxCount: 100),
        0,
      );
    });

    test('builds country traffic points from metric rows', () {
      final points = CountryTrafficScale.fromRows(
        const [
          MetricRow(value: 'US', count: 100),
          MetricRow(value: 'IN', count: 25),
          MetricRow(value: 'Unknown', count: 10),
        ],
      );

      expect(points, hasLength(2));
      expect(points.first.iso2, 'US');
      expect(points.first.mapColorKey, 'uS');
      expect(points.last.intensity, closeTo(0.5, 0.001));
    });
  });
}
