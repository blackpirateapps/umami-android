import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/network/auth_interceptor.dart';
import '../../core/network/dio_failure_mapper.dart';
import '../../core/network/large_payload_transformer.dart';
import '../../core/network/retry_interceptor.dart';
import '../../core/security/secure_session_store.dart';
import '../../core/time/timezone_normalizer.dart';
import '../../data/local/app_database.dart';
import '../../data/local/local_analytics_data_source.dart';
import '../../data/mappers/umami_mappers.dart';
import '../../data/remote/umami_api_service.dart';
import '../../data/remote/umami_token_refresher.dart';
import '../../data/repositories/analytics_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/use_cases/authenticate_user_use_case.dart';
import '../../domain/use_cases/get_dashboard_data_use_case.dart';
import '../../domain/use_cases/get_metric_page_use_case.dart';
import '../../domain/use_cases/get_sessions_use_case.dart';
import '../../domain/use_cases/get_website_stats_use_case.dart';
import '../../domain/use_cases/sync_website_data_use_case.dart';

part 'dependencies.g.dart';

@Riverpod(keepAlive: true)
FlutterSecureStorage secureStorage(SecureStorageRef ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
}

@Riverpod(keepAlive: true)
SecureSessionStore secureSessionStore(SecureSessionStoreRef ref) {
  return SecureSessionStore(ref.watch(secureStorageProvider));
}

@Riverpod(keepAlive: true)
TimezoneNormalizer timezoneNormalizer(TimezoneNormalizerRef ref) {
  return const TimezoneNormalizer();
}

@Riverpod(keepAlive: true)
DioFailureMapper dioFailureMapper(DioFailureMapperRef ref) {
  return const DioFailureMapper();
}

@Riverpod(keepAlive: true)
Dio dio(DioRef ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      responseType: ResponseType.json,
      headers: const {
        'Accept': 'application/json',
      },
    ),
  )..transformer = LargePayloadTransformer();

  final sessionStore = ref.watch(secureSessionStoreProvider);
  final tokenRefresher = UmamiTokenRefresher(
    dio: dio,
    sessionStore: sessionStore,
  );

  dio.interceptors.addAll([
    AuthInterceptor(
      dio: dio,
      sessionStore: sessionStore,
      tokenRefresher: tokenRefresher,
    ),
    RetryInterceptor(dio: dio),
  ]);

  return dio;
}

@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
}

@Riverpod(keepAlive: true)
WebsiteMapper websiteMapper(WebsiteMapperRef ref) {
  return const WebsiteMapper();
}

@Riverpod(keepAlive: true)
StatsMapper statsMapper(StatsMapperRef ref) {
  return const StatsMapper();
}

@Riverpod(keepAlive: true)
PageviewsMapper pageviewsMapper(PageviewsMapperRef ref) {
  return PageviewsMapper(ref.watch(timezoneNormalizerProvider));
}

@Riverpod(keepAlive: true)
MetricMapper metricMapper(MetricMapperRef ref) {
  return const MetricMapper();
}

@Riverpod(keepAlive: true)
SessionMapper sessionMapper(SessionMapperRef ref) {
  return const SessionMapper();
}

@Riverpod(keepAlive: true)
UmamiApiService umamiApiService(UmamiApiServiceRef ref) {
  return UmamiApiService(
    dio: ref.watch(dioProvider),
    timezoneNormalizer: ref.watch(timezoneNormalizerProvider),
  );
}

@Riverpod(keepAlive: true)
LocalAnalyticsDataSource localAnalyticsDataSource(
  LocalAnalyticsDataSourceRef ref,
) {
  return LocalAnalyticsDataSource(
    database: ref.watch(appDatabaseProvider),
    websiteMapper: ref.watch(websiteMapperProvider),
    statsMapper: ref.watch(statsMapperProvider),
    metricMapper: ref.watch(metricMapperProvider),
  );
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepositoryImpl(
    apiService: ref.watch(umamiApiServiceProvider),
    sessionStore: ref.watch(secureSessionStoreProvider),
    failureMapper: ref.watch(dioFailureMapperProvider),
  );
}

@Riverpod(keepAlive: true)
AnalyticsRepository analyticsRepository(AnalyticsRepositoryRef ref) {
  return AnalyticsRepositoryImpl(
    apiService: ref.watch(umamiApiServiceProvider),
    localDataSource: ref.watch(localAnalyticsDataSourceProvider),
    websiteMapper: ref.watch(websiteMapperProvider),
    statsMapper: ref.watch(statsMapperProvider),
    pageviewsMapper: ref.watch(pageviewsMapperProvider),
    metricMapper: ref.watch(metricMapperProvider),
    sessionMapper: ref.watch(sessionMapperProvider),
    failureMapper: ref.watch(dioFailureMapperProvider),
  );
}

@Riverpod(keepAlive: true)
AuthenticateUserUseCase authenticateUserUseCase(
  AuthenticateUserUseCaseRef ref,
) {
  return AuthenticateUserUseCase(ref.watch(authRepositoryProvider));
}

@Riverpod(keepAlive: true)
SyncWebsiteDataUseCase syncWebsiteDataUseCase(
  SyncWebsiteDataUseCaseRef ref,
) {
  return SyncWebsiteDataUseCase(ref.watch(analyticsRepositoryProvider));
}

@Riverpod(keepAlive: true)
GetWebsiteStatsUseCase getWebsiteStatsUseCase(
  GetWebsiteStatsUseCaseRef ref,
) {
  return GetWebsiteStatsUseCase(ref.watch(analyticsRepositoryProvider));
}

@Riverpod(keepAlive: true)
GetDashboardDataUseCase getDashboardDataUseCase(
  GetDashboardDataUseCaseRef ref,
) {
  return GetDashboardDataUseCase(ref.watch(analyticsRepositoryProvider));
}

@Riverpod(keepAlive: true)
GetMetricPageUseCase getMetricPageUseCase(GetMetricPageUseCaseRef ref) {
  return GetMetricPageUseCase(ref.watch(analyticsRepositoryProvider));
}

@Riverpod(keepAlive: true)
GetSessionsUseCase getSessionsUseCase(GetSessionsUseCaseRef ref) {
  return GetSessionsUseCase(ref.watch(analyticsRepositoryProvider));
}
