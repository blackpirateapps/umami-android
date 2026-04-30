import 'analytics_query.dart';

final class MetricReport {
  const MetricReport({
    required this.type,
    required this.rows,
    required this.total,
    required this.offset,
    required this.limit,
    required this.fetchedAt,
  });

  final MetricType type;
  final List<MetricRow> rows;
  final int total;
  final int offset;
  final int limit;
  final DateTime fetchedAt;

  bool get hasMore => offset + rows.length < total;
}

final class MetricRow {
  const MetricRow({
    required this.value,
    required this.count,
  });

  final String value;
  final int count;
}
