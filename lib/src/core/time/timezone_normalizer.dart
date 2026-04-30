final class TimezoneNormalizer {
  const TimezoneNormalizer();

  DateTime fromApiTimestamp(
    Object value, {
    int? timezoneOffsetMinutes,
  }) {
    final utc = switch (value) {
      final int milliseconds => DateTime.fromMillisecondsSinceEpoch(
          milliseconds,
          isUtc: true,
        ),
      final String iso => DateTime.parse(iso).toUtc(),
      _ => throw FormatException('Unsupported timestamp value: $value'),
    };

    if (timezoneOffsetMinutes == null) {
      return utc.toLocal();
    }

    return utc.add(Duration(minutes: timezoneOffsetMinutes));
  }

  int toEpochMilliseconds(DateTime value) {
    return value.toUtc().millisecondsSinceEpoch;
  }
}
