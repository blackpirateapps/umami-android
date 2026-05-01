final class SessionReport {
  const SessionReport({
    required this.rows,
    required this.count,
    required this.page,
    required this.pageSize,
    required this.fetchedAt,
  });

  final List<WebsiteSession> rows;
  final int count;
  final int page;
  final int pageSize;
  final DateTime fetchedAt;

  bool get hasMore => page * pageSize < count;
}

final class WebsiteSession {
  const WebsiteSession({
    required this.id,
    required this.websiteId,
    required this.hostname,
    required this.browser,
    required this.os,
    required this.device,
    required this.screen,
    required this.language,
    required this.country,
    required this.region,
    required this.city,
    required this.visits,
    required this.views,
    required this.events,
    required this.firstAt,
    required this.lastAt,
    required this.createdAt,
  });

  final String id;
  final String websiteId;
  final String hostname;
  final String browser;
  final String os;
  final String device;
  final String screen;
  final String language;
  final String country;
  final String region;
  final String city;
  final int visits;
  final int views;
  final int events;
  final DateTime? firstAt;
  final DateTime? lastAt;
  final DateTime? createdAt;
}
