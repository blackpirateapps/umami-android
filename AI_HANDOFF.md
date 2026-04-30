# AI Handoff

## Project Goal

This repository is a Flutter Android client for Umami Analytics REST API v2. It implements a Clean Architecture data engine with Riverpod generated providers, Dio networking, Freezed DTOs, Drift offline caching, and secure JWT/session storage.

## Current Structure

- `lib/src/domain`: pure Dart entities, query/filter value objects, repository contracts, and use cases.
- `lib/src/data/dto`: Freezed API response DTOs for auth, websites, stats, pageviews, and metrics.
- `lib/src/data/remote`: `UmamiApiService` and token refresh re-login support.
- `lib/src/data/local`: Drift cache database and local data source.
- `lib/src/data/repositories`: cache-first repository implementations.
- `lib/src/application/providers`: `@riverpod` dependency graph and `AsyncNotifier` controllers.
- `lib/src/presentation`: shadcn-style login and dashboard pages.

## Important Architecture Notes

- Business logic does not consume raw `Map<String, dynamic>` values. Maps are isolated to DTO parsing and cache JSON serialization in the data layer.
- `AnalyticsRepositoryImpl` uses cache-first behavior with network update and offline fallback.
- `getDashboard` launches website, stats, pageviews, and metric requests concurrently with `Future.wait`.
- Dashboard and metric controllers are generated Riverpod auto-dispose providers by default. Long-lived app dependencies are marked `keepAlive`.
- Umami does not expose a conventional refresh-token endpoint. The auth interceptor refreshes expired JWTs by re-posting `/api/auth/login` with credentials stored in `flutter_secure_storage`.
- Time-series timestamps are normalized through `TimezoneNormalizer` using the user's local timezone offset captured in `AnalyticsDateRange`.
- Latest Umami API compatibility matters: `GET /api/websites/:id/metrics` uses `type=path`, not the old v2 `type=url`; URL filters are sent as `path`; pageview series requests include `timezone=UTC`; stats and metrics requests intentionally omit `unit`.

## Code Generation

The project relies on generated files from:

- `freezed`
- `json_serializable`
- `drift_dev`
- `riverpod_generator`

Run this before analyze/build/test:

```sh
dart run build_runner build --delete-conflicting-outputs
```

Generated files are not checked in yet; CI creates them before analysis and APK build.

## Release Workflow

`.github/workflows/release-apk.yml`:

- Installs Java and Flutter.
- Runs `flutter create --platforms android --project-name umami_android --org app.blackpirate.umami .` because Android scaffolding is intentionally generated in CI.
- Creates an ephemeral release keystore with `keytool`.
- Patches the generated Gradle app file for release signing.
- Runs `flutter pub get`, codegen, `flutter analyze`, `flutter test`, and `flutter build apk --release`.
- Uploads `build/app/outputs/flutter-apk/app-release.apk`.

## Next-Agent Checklist

1. Run code generation on a machine with Flutter/Dart.
2. Validate `shadcn_ui` API compatibility, especially `ShadInput.controller` and icon names from `LucideIcons`.
3. Verify Umami response envelopes against a real v2 instance. `UmamiApiService` accepts plain lists and common `{data/items/results}` envelopes.
4. Consider adding repository unit tests with mocked `UmamiApiService` and an in-memory Drift executor.
