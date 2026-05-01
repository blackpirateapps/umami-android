final class SessionsResponseDto {
  const SessionsResponseDto({
    required this.data,
    required this.count,
    required this.page,
    required this.pageSize,
  });

  factory SessionsResponseDto.fromJson(Map<String, dynamic> json) {
    final data = _readList(json['data'] ?? json['items'] ?? json['results'])
        .map((item) => SessionDto.fromJson(_readObject(item)))
        .toList(growable: false);

    return SessionsResponseDto(
      data: data,
      count: _readInt(json['count'] ?? json['total']) ?? data.length,
      page: _readInt(json['page']) ?? 1,
      pageSize: _readInt(json['pageSize']) ?? data.length,
    );
  }

  final List<SessionDto> data;
  final int count;
  final int page;
  final int pageSize;
}

final class SessionDto {
  const SessionDto({
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

  factory SessionDto.fromJson(Map<String, dynamic> json) {
    return SessionDto(
      id: _readString(json['id']),
      websiteId: _readString(json['websiteId']),
      hostname: _readString(json['hostname']),
      browser: _readString(json['browser']),
      os: _readString(json['os']),
      device: _readString(json['device']),
      screen: _readString(json['screen']),
      language: _readString(json['language']),
      country: _readString(json['country']).toUpperCase(),
      region: _readString(json['region']),
      city: _readString(json['city']),
      visits: _readInt(json['visits']) ?? 0,
      views: _readInt(json['views']) ?? 0,
      events: _readInt(json['events']) ?? 0,
      firstAt: _readDate(json['firstAt']),
      lastAt: _readDate(json['lastAt']),
      createdAt: _readDate(json['createdAt']),
    );
  }

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

List<dynamic> _readList(Object? value) {
  return value is List ? value : const <dynamic>[];
}

Map<String, dynamic> _readObject(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}

String _readString(Object? value) {
  return value?.toString() ?? '';
}

int? _readInt(Object? value) {
  return switch (value) {
    final int number => number,
    final num number => number.round(),
    final String text => int.tryParse(text),
    _ => null,
  };
}

DateTime? _readDate(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) {
    return null;
  }
  return DateTime.tryParse(text);
}
