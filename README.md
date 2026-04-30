# Umami Android

An offline-capable Flutter Android client for the Umami Analytics REST API v2.

The app is structured around Clean Architecture:

- `lib/src/domain`: pure entities, repository contracts, value objects, use cases.
- `lib/src/data`: Dio API service, DTOs, mappers, Drift cache, repository implementations.
- `lib/src/application`: Riverpod generated providers and AsyncNotifier state controllers.
- `lib/src/presentation`: shadcn-style Flutter screens.

## Local Development

Flutter is not installed in this environment. On a machine with Flutter:

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

## Release APK

The GitHub Actions workflow in `.github/workflows/release-apk.yml` installs Flutter,
generates missing Android platform scaffolding, creates an ephemeral release keystore,
runs code generation, analyzes/tests the app, and uploads a signed release APK.
