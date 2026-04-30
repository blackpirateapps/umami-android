import 'metric_report.dart';
import 'session_stats.dart';
import 'time_series_point.dart';
import 'website.dart';

final class DashboardData {
  const DashboardData({
    required this.website,
    required this.stats,
    required this.pageviews,
    required this.topPages,
    required this.referrers,
    required this.browsers,
    required this.operatingSystems,
    required this.devices,
    required this.countries,
    required this.fetchedAt,
    this.isStale = false,
  });

  final Website website;
  final SessionStats stats;
  final List<TimeSeriesPoint> pageviews;
  final MetricReport topPages;
  final MetricReport referrers;
  final MetricReport browsers;
  final MetricReport operatingSystems;
  final MetricReport devices;
  final MetricReport countries;
  final DateTime fetchedAt;
  final bool isStale;
}
