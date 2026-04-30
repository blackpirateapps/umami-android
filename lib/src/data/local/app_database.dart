import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class CachedWebsites extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get domain => text()();
  TextColumn get shareId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedStats extends Table {
  TextColumn get websiteId => text()();
  DateTimeColumn get startAt => dateTime()();
  DateTimeColumn get endAt => dateTime()();
  IntColumn get visitors => integer()();
  IntColumn get pageviews => integer()();
  IntColumn get visits => integer()();
  IntColumn get bounces => integer()();
  IntColumn get totalTimeSeconds => integer()();
  RealColumn get bounceRate => real()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {websiteId, startAt, endAt};
}

class CachedPageviews extends Table {
  TextColumn get websiteId => text()();
  DateTimeColumn get startAt => dateTime()();
  DateTimeColumn get endAt => dateTime()();
  TextColumn get pointsJson => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {websiteId, startAt, endAt};
}

class CachedMetrics extends Table {
  TextColumn get websiteId => text()();
  DateTimeColumn get startAt => dateTime()();
  DateTimeColumn get endAt => dateTime()();
  TextColumn get metricType => text()();
  TextColumn get queryKey => text().withDefault(const Constant(''))();
  IntColumn get offset => integer()();
  IntColumn get limit => integer()();
  IntColumn get total => integer()();
  TextColumn get rowsJson => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {
        websiteId,
        startAt,
        endAt,
        metricType,
        queryKey,
        offset,
        limit,
      };
}

@DriftDatabase(
  tables: [
    CachedWebsites,
    CachedStats,
    CachedPageviews,
    CachedMetrics,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'umami_android_cache'));

  @override
  int get schemaVersion => 1;
}
