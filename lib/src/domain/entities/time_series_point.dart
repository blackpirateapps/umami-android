final class TimeSeriesPoint {
  const TimeSeriesPoint({
    required this.timestamp,
    required this.pageviews,
    required this.sessions,
  });

  final DateTime timestamp;
  final int pageviews;
  final int sessions;
}
