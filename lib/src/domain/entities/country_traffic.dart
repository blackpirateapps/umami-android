import 'dart:math' as math;

import 'metric_report.dart';

final class CountryTrafficPoint {
  const CountryTrafficPoint({
    required this.iso2,
    required this.mapColorKey,
    required this.count,
    required this.intensity,
  });

  final String iso2;
  final String mapColorKey;
  final int count;
  final double intensity;
}

final class CountryTrafficScale {
  const CountryTrafficScale._();

  static String? normalizeIso2(String value) {
    final code = value.trim().toUpperCase();
    if (code.length != 2) {
      return null;
    }

    final valid = code.codeUnits.every((unit) => unit >= 65 && unit <= 90);
    return valid ? code : null;
  }

  static String? mapColorKey(String iso2) {
    final code = normalizeIso2(iso2);
    if (code == null) {
      return null;
    }
    return '${code[0].toLowerCase()}${code[1]}';
  }

  static double intensity({
    required int count,
    required int maxCount,
  }) {
    if (count <= 0 || maxCount <= 0) {
      return 0;
    }

    final normalized = math.sqrt(count / maxCount);
    return normalized.clamp(0.18, 1).toDouble();
  }

  static List<CountryTrafficPoint> fromRows(List<MetricRow> rows) {
    final validRows = rows
        .map((row) => (row: row, iso2: normalizeIso2(row.value)))
        .where((item) => item.iso2 != null)
        .toList(growable: false);

    final maxCount = validRows.fold<int>(
      0,
      (max, item) => item.row.count > max ? item.row.count : max,
    );

    return validRows
        .map(
          (item) => CountryTrafficPoint(
            iso2: item.iso2!,
            mapColorKey: mapColorKey(item.iso2!)!,
            count: item.row.count,
            intensity: intensity(
              count: item.row.count,
              maxCount: maxCount,
            ),
          ),
        )
        .toList(growable: false);
  }
}
