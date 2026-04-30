enum MetricType {
  url,
  referrer,
  browser,
  os,
  device,
  country,
}

extension MetricTypeApiName on MetricType {
  String get apiName {
    return switch (this) {
      MetricType.url => 'url',
      MetricType.referrer => 'referrer',
      MetricType.browser => 'browser',
      MetricType.os => 'os',
      MetricType.device => 'device',
      MetricType.country => 'country',
    };
  }
}

enum TimeUnit {
  hour,
  day,
  month,
}

extension TimeUnitApiName on TimeUnit {
  String get apiName {
    return switch (this) {
      TimeUnit.hour => 'hour',
      TimeUnit.day => 'day',
      TimeUnit.month => 'month',
    };
  }
}

final class AnalyticsDateRange {
  const AnalyticsDateRange({
    required this.startAt,
    required this.endAt,
    this.unit = TimeUnit.day,
    this.timezoneOffsetMinutes,
  });

  factory AnalyticsDateRange.last7Days({DateTime? now}) {
    final localNow = now ?? DateTime.now();
    final end = DateTime(
      localNow.year,
      localNow.month,
      localNow.day,
      23,
      59,
      59,
      999,
    );
    final start = DateTime(
      end.year,
      end.month,
      end.day,
    ).subtract(const Duration(days: 6));
    return AnalyticsDateRange(
      startAt: start,
      endAt: end,
      unit: TimeUnit.day,
      timezoneOffsetMinutes: localNow.timeZoneOffset.inMinutes,
    );
  }

  final DateTime startAt;
  final DateTime endAt;
  final TimeUnit unit;
  final int? timezoneOffsetMinutes;

  @override
  int get hashCode => Object.hash(
        startAt,
        endAt,
        unit,
        timezoneOffsetMinutes,
      );

  @override
  bool operator ==(Object other) {
    return other is AnalyticsDateRange &&
        other.startAt == startAt &&
        other.endAt == endAt &&
        other.unit == unit &&
        other.timezoneOffsetMinutes == timezoneOffsetMinutes;
  }
}

final class AnalyticsFilters {
  const AnalyticsFilters({
    this.url,
    this.referrer,
    this.browser,
    this.os,
    this.device,
    this.country,
  });

  final String? url;
  final String? referrer;
  final String? browser;
  final String? os;
  final String? device;
  final String? country;

  String get cacheKey {
    return [
      url ?? '',
      referrer ?? '',
      browser ?? '',
      os ?? '',
      device ?? '',
      country ?? '',
    ].join('|');
  }

  @override
  bool operator ==(Object other) {
    return other is AnalyticsFilters &&
        other.url == url &&
        other.referrer == referrer &&
        other.browser == browser &&
        other.os == os &&
        other.device == device &&
        other.country == country;
  }

  @override
  int get hashCode => Object.hash(
        url,
        referrer,
        browser,
        os,
        device,
        country,
      );
}

final class MetricQuery {
  const MetricQuery({
    required this.websiteId,
    required this.range,
    required this.type,
    this.filters = const AnalyticsFilters(),
    this.offset = 0,
    this.limit = 25,
    this.search,
  });

  final String websiteId;
  final AnalyticsDateRange range;
  final MetricType type;
  final AnalyticsFilters filters;
  final int offset;
  final int limit;
  final String? search;

  String get cacheKey => '${search ?? ''}::${filters.cacheKey}';

  MetricQuery nextPage() {
    return MetricQuery(
      websiteId: websiteId,
      range: range,
      type: type,
      filters: filters,
      offset: offset + limit,
      limit: limit,
      search: search,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MetricQuery &&
        other.websiteId == websiteId &&
        other.range == range &&
        other.type == type &&
        other.filters == filters &&
        other.offset == offset &&
        other.limit == limit &&
        other.search == search;
  }

  @override
  int get hashCode => Object.hash(
        websiteId,
        range,
        type,
        filters,
        offset,
        limit,
        search,
      );
}

final class DashboardRequest {
  const DashboardRequest({
    required this.websiteId,
    required this.range,
  });

  final String websiteId;
  final AnalyticsDateRange range;

  @override
  bool operator ==(Object other) {
    return other is DashboardRequest &&
        other.websiteId == websiteId &&
        other.range == range;
  }

  @override
  int get hashCode => Object.hash(websiteId, range);
}
