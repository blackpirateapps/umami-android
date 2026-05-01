final class SessionStats {
  const SessionStats({
    required this.visitors,
    required this.pageviews,
    required this.visits,
    required this.bounces,
    required this.totalTimeSeconds,
    required this.bounceRate,
    this.previousVisitors,
    this.previousPageviews,
    this.previousVisits,
    this.previousBounces,
    this.previousTotalTimeSeconds,
  });

  final int visitors;
  final int pageviews;
  final int visits;
  final int bounces;
  final int totalTimeSeconds;
  final double bounceRate;
  final int? previousVisitors;
  final int? previousPageviews;
  final int? previousVisits;
  final int? previousBounces;
  final int? previousTotalTimeSeconds;

  int get averageVisitSeconds {
    return visits == 0 ? 0 : totalTimeSeconds ~/ visits;
  }

  int? get previousAverageVisitSeconds {
    final previousVisitsValue = previousVisits;
    final previousTotalTimeValue = previousTotalTimeSeconds;
    if (previousVisitsValue == null ||
        previousTotalTimeValue == null ||
        previousVisitsValue == 0) {
      return null;
    }
    return previousTotalTimeValue ~/ previousVisitsValue;
  }

  double? get previousBounceRate {
    final previousVisitsValue = previousVisits;
    final previousBouncesValue = previousBounces;
    if (previousVisitsValue == null ||
        previousBouncesValue == null ||
        previousVisitsValue == 0) {
      return null;
    }
    return previousBouncesValue / previousVisitsValue;
  }

  double? get visitorsChange => _percentChange(visitors, previousVisitors);

  double? get pageviewsChange => _percentChange(pageviews, previousPageviews);

  double? get visitsChange => _percentChange(visits, previousVisits);

  double? get bounceRateChange => _percentChange(
        bounceRate,
        previousBounceRate,
      );

  double? get averageVisitSecondsChange => _percentChange(
        averageVisitSeconds,
        previousAverageVisitSeconds,
      );

  static double? _percentChange(num current, num? previous) {
    if (previous == null || previous == 0) {
      return null;
    }
    return (current - previous) / previous.abs();
  }
}
