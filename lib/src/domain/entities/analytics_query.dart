enum MetricType {
  path,
  referrer,
  browser,
  os,
  device,
  country,
}

extension MetricTypeApiName on MetricType {
  String get apiName {
    return switch (this) {
      MetricType.path => 'path',
      MetricType.referrer => 'referrer',
      MetricType.browser => 'browser',
      MetricType.os => 'os',
      MetricType.device => 'device',
      MetricType.country => 'country',
    };
  }
}

const _filterUnset = Object();

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
    this.timezone = 'UTC',
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
      timezone: 'UTC',
      timezoneOffsetMinutes: localNow.timeZoneOffset.inMinutes,
    );
  }

  final DateTime startAt;
  final DateTime endAt;
  final TimeUnit unit;
  final String timezone;
  final int? timezoneOffsetMinutes;

  @override
  int get hashCode => Object.hash(
        startAt,
        endAt,
        unit,
        timezone,
        timezoneOffsetMinutes,
      );

  @override
  bool operator ==(Object other) {
    return other is AnalyticsDateRange &&
        other.startAt == startAt &&
        other.endAt == endAt &&
        other.unit == unit &&
        other.timezone == timezone &&
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

  bool get isEmpty {
    return url == null &&
        referrer == null &&
        browser == null &&
        os == null &&
        device == null &&
        country == null;
  }

  bool get isNotEmpty => !isEmpty;

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

  AnalyticsFilters copyWith({
    Object? url = _filterUnset,
    Object? referrer = _filterUnset,
    Object? browser = _filterUnset,
    Object? os = _filterUnset,
    Object? device = _filterUnset,
    Object? country = _filterUnset,
  }) {
    return AnalyticsFilters(
      url: identical(url, _filterUnset) ? this.url : url as String?,
      referrer: identical(referrer, _filterUnset)
          ? this.referrer
          : referrer as String?,
      browser:
          identical(browser, _filterUnset) ? this.browser : browser as String?,
      os: identical(os, _filterUnset) ? this.os : os as String?,
      device: identical(device, _filterUnset) ? this.device : device as String?,
      country:
          identical(country, _filterUnset) ? this.country : country as String?,
    );
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
    this.filters = const AnalyticsFilters(),
  });

  final String websiteId;
  final AnalyticsDateRange range;
  final AnalyticsFilters filters;

  @override
  bool operator ==(Object other) {
    return other is DashboardRequest &&
        other.websiteId == websiteId &&
        other.range == range &&
        other.filters == filters;
  }

  @override
  int get hashCode => Object.hash(websiteId, range, filters);
}

final class SessionsQuery {
  const SessionsQuery({
    required this.websiteId,
    required this.range,
    this.filters = const AnalyticsFilters(),
    this.page = 1,
    this.pageSize = 20,
    this.search,
  });

  final String websiteId;
  final AnalyticsDateRange range;
  final AnalyticsFilters filters;
  final int page;
  final int pageSize;
  final String? search;

  SessionsQuery nextPage() {
    return SessionsQuery(
      websiteId: websiteId,
      range: range,
      filters: filters,
      page: page + 1,
      pageSize: pageSize,
      search: search,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SessionsQuery &&
        other.websiteId == websiteId &&
        other.range == range &&
        other.filters == filters &&
        other.page == page &&
        other.pageSize == pageSize &&
        other.search == search;
  }

  @override
  int get hashCode => Object.hash(
        websiteId,
        range,
        filters,
        page,
        pageSize,
        search,
      );
}
