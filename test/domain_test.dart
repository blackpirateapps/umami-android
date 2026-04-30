import 'package:flutter_test/flutter_test.dart';
import 'package:umami_android/src/domain/entities/analytics_query.dart';

void main() {
  test('last7Days creates an inclusive seven day range', () {
    final range = AnalyticsDateRange.last7Days(
      now: DateTime(2026, 4, 30, 10),
    );

    expect(range.startAt, DateTime(2026, 4, 24));
    expect(range.endAt, DateTime(2026, 4, 30, 23, 59, 59, 999));
    expect(range.unit, TimeUnit.day);
  });
}
