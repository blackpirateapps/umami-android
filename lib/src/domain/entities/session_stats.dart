final class SessionStats {
  const SessionStats({
    required this.visitors,
    required this.pageviews,
    required this.visits,
    required this.bounces,
    required this.totalTimeSeconds,
    required this.bounceRate,
  });

  final int visitors;
  final int pageviews;
  final int visits;
  final int bounces;
  final int totalTimeSeconds;
  final double bounceRate;
}
