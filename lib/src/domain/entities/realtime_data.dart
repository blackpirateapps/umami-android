final class RealtimeData {
  const RealtimeData({
    required this.activeVisitors,
    required this.pageviewsLastMinute,
    required this.timestamp,
  });

  final int activeVisitors;
  final int pageviewsLastMinute;
  final DateTime timestamp;
}
