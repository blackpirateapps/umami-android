import 'analytics_query.dart';

enum AnalyticsDateRangePreset {
  last24Hours('Last 24 hours'),
  thisWeek('This week'),
  last7Days('Last 7 days'),
  thisMonth('This month'),
  last30Days('Last 30 days'),
  last60Days('Last 60 days'),
  last90Days('Last 90 days'),
  thisYear('This year'),
  last6Months('Last 6 months'),
  last12Months('Last 12 months'),
  allTime('All time'),
  custom('Custom range');

  const AnalyticsDateRangePreset(this.label);

  final String label;
}

final class AnalyticsDateRangeSelection {
  const AnalyticsDateRangeSelection.preset(this.preset)
      : customStartAt = null,
        customEndAt = null;

  const AnalyticsDateRangeSelection.custom({
    required DateTime startAt,
    required DateTime endAt,
  })  : preset = AnalyticsDateRangePreset.custom,
        customStartAt = startAt,
        customEndAt = endAt;

  final AnalyticsDateRangePreset preset;
  final DateTime? customStartAt;
  final DateTime? customEndAt;

  bool get isCustom => preset == AnalyticsDateRangePreset.custom;

  AnalyticsDateRange resolve({
    DateTime? now,
    DateTime? allTimeStartAt,
  }) {
    final localNow = now ?? DateTime.now();
    final timezoneOffsetMinutes = localNow.timeZoneOffset.inMinutes;

    final range = switch (preset) {
      AnalyticsDateRangePreset.last24Hours => _DateRangeParts(
          startAt: _startOfHour(localNow).subtract(const Duration(hours: 23)),
          endAt: _endOfHour(localNow),
          unit: TimeUnit.hour,
        ),
      AnalyticsDateRangePreset.thisWeek => _DateRangeParts(
          startAt: _startOfDay(
            localNow.subtract(Duration(days: localNow.weekday - 1)),
          ),
          endAt: _endOfDay(localNow),
          unit: TimeUnit.day,
        ),
      AnalyticsDateRangePreset.last7Days => _DateRangeParts(
          startAt: _startOfDay(localNow).subtract(const Duration(days: 6)),
          endAt: _endOfDay(localNow),
          unit: TimeUnit.day,
        ),
      AnalyticsDateRangePreset.thisMonth => _DateRangeParts(
          startAt: DateTime(localNow.year, localNow.month),
          endAt: _endOfDay(localNow),
          unit: TimeUnit.day,
        ),
      AnalyticsDateRangePreset.last30Days => _DateRangeParts(
          startAt: _startOfDay(localNow).subtract(const Duration(days: 29)),
          endAt: _endOfDay(localNow),
          unit: TimeUnit.day,
        ),
      AnalyticsDateRangePreset.last60Days => _DateRangeParts(
          startAt: _startOfDay(localNow).subtract(const Duration(days: 59)),
          endAt: _endOfDay(localNow),
          unit: TimeUnit.day,
        ),
      AnalyticsDateRangePreset.last90Days => _DateRangeParts(
          startAt: _startOfDay(localNow).subtract(const Duration(days: 89)),
          endAt: _endOfDay(localNow),
          unit: TimeUnit.day,
        ),
      AnalyticsDateRangePreset.thisYear => _DateRangeParts(
          startAt: DateTime(localNow.year),
          endAt: _endOfDay(localNow),
          unit: TimeUnit.month,
        ),
      AnalyticsDateRangePreset.last6Months => _DateRangeParts(
          startAt: _startOfMonth(_addMonths(localNow, -5)),
          endAt: _endOfDay(localNow),
          unit: TimeUnit.month,
        ),
      AnalyticsDateRangePreset.last12Months => _DateRangeParts(
          startAt: _startOfMonth(_addMonths(localNow, -11)),
          endAt: _endOfDay(localNow),
          unit: TimeUnit.month,
        ),
      AnalyticsDateRangePreset.allTime => _DateRangeParts(
          startAt: _startOfDay(_safeAllTimeStart(localNow, allTimeStartAt)),
          endAt: _endOfDay(localNow),
          unit: TimeUnit.month,
        ),
      AnalyticsDateRangePreset.custom => _customParts(),
    };

    return AnalyticsDateRange(
      startAt: range.startAt,
      endAt: range.endAt,
      unit: range.unit,
      timezone: 'UTC',
      timezoneOffsetMinutes: timezoneOffsetMinutes,
    );
  }

  _DateRangeParts _customParts() {
    final start = customStartAt;
    final end = customEndAt;
    if (start == null || end == null) {
      throw StateError('Custom date ranges require a start and end date.');
    }

    final normalizedStart = _startOfDay(start);
    final normalizedEnd = _endOfDay(end);
    final orderedStart =
        normalizedStart.isBefore(normalizedEnd) ? normalizedStart : _startOfDay(end);
    final orderedEnd =
        normalizedStart.isBefore(normalizedEnd) ? normalizedEnd : _endOfDay(start);

    return _DateRangeParts(
      startAt: orderedStart,
      endAt: orderedEnd,
      unit: _unitForCustomRange(orderedStart, orderedEnd),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AnalyticsDateRangeSelection &&
        other.preset == preset &&
        other.customStartAt == customStartAt &&
        other.customEndAt == customEndAt;
  }

  @override
  int get hashCode => Object.hash(preset, customStartAt, customEndAt);
}

final class _DateRangeParts {
  const _DateRangeParts({
    required this.startAt,
    required this.endAt,
    required this.unit,
  });

  final DateTime startAt;
  final DateTime endAt;
  final TimeUnit unit;
}

DateTime _startOfHour(DateTime value) {
  return DateTime(value.year, value.month, value.day, value.hour);
}

DateTime _endOfHour(DateTime value) {
  return DateTime(value.year, value.month, value.day, value.hour, 59, 59, 999);
}

DateTime _startOfDay(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

DateTime _endOfDay(DateTime value) {
  return DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
}

DateTime _startOfMonth(DateTime value) {
  return DateTime(value.year, value.month);
}

DateTime _addMonths(DateTime value, int months) {
  return DateTime(value.year, value.month + months);
}

DateTime _safeAllTimeStart(DateTime now, DateTime? allTimeStartAt) {
  final fallback = DateTime(2000);
  final start = allTimeStartAt ?? fallback;
  return start.isAfter(now) ? now : start;
}

TimeUnit _unitForCustomRange(DateTime startAt, DateTime endAt) {
  final duration = endAt.difference(startAt);
  if (duration <= const Duration(days: 1)) {
    return TimeUnit.hour;
  }
  if (duration.inDays <= 120) {
    return TimeUnit.day;
  }
  return TimeUnit.month;
}
