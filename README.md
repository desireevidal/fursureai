# Fursure

A Flutter app that uses on-device machine learning to predict cat breeds from images and cat gender from audio recordings.

## Features

- **Cat Breed Prediction**: Upload or capture a photo of a cat to identify its breed using TensorFlow Lite
- **Gender Prediction**: Record cat audio to predict whether the cat is male or female
- **Prediction History**: View past predictions stored locally
- **On-Device ML**: All predictions run locally on the device - no internet required

## Tech Stack

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11+-0175C2?logo=dart)](https://dart.dev)
[![Riverpod](https://img.shields.io/badge/Riverpod-2.6-400998)](https://riverpod.dev)
[![GoRouter](https://img.shields.io/badge/GoRouter-14.8-000000)](https://pub.dev/packages/go_router)
[![TensorFlow Lite](https://img.shields.io/badge/TensorFlow%20Lite-FF6F00?logo=tensorflow)](https://www.tensorflow.org/lite)
[![SQLite](https://img.shields.io/badge/SQLite-003F87?logo=sqlite)](https://www.sqlite.org)
[![Dio](https://img.shields.io/badge/Dio-5.7-157_2F6)](https://pub.dev/packages/dio)

## Prerequisites

- Flutter SDK 3.11+
- Dart SDK 3.11+
- Android SDK (minSdk 21+) / iOS 13.0+

## Setup

### 1. Clone the repository

```bash
git clone <repository-url>
cd fursure
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure model sources

The app downloads remote TFLite models on first launch. Model URLs are provided at build time via `--dart-define-from-file`. Config files live in `config/`:

| File | Purpose |
|---|---|
| `config/dev.json` | Placeholder mode — no model downloads, instant responses |
| `config/prod.json` | Real models — fill in your actual model URLs before building |

**Build variables:**

| Variable | Required | Description |
|---|---|---|
| `USE_PLACEHOLDERS` | No | Set `"true"` to force placeholder mode for both models |
| `BREED_MODEL_URL` | No | Download URL for the breed TFLite model |
| `BREED_MODEL_SHA256` | No | Expected SHA-256 hex digest of the breed model file |
| `GENDER_MODEL_URL` | No | Download URL for the gender TFLite model |
| `GENDER_MODEL_SHA256` | No | Expected SHA-256 hex digest of the gender model file |

When a URL is omitted, that model falls back to placeholder mode automatically — no flag required.

When a SHA-256 hash is provided, the app verifies the downloaded file (and any previously cached copy) against it. A mismatch throws an error — the model will not load. Leave the hash empty to skip verification.

**Run in dev (placeholder mode):**

```bash
flutter run --dart-define-from-file=config/dev.json
```

**Run with real models:**

Edit `config/prod.json` with your actual model URLs and (optionally) SHA-256 hashes, then:

```bash
flutter run --dart-define-from-file=config/prod.json
```

Example `config/prod.json`:

```json
{
  "USE_PLACEHOLDERS": "false",
  "BREED_MODEL_URL": "https://your-host.example/breed.tflite",
  "BREED_MODEL_SHA256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "GENDER_MODEL_URL": "https://your-host.example/gender.tflite",
  "GENDER_MODEL_SHA256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
}
```

Omit the `*_SHA256` keys (or leave them as `""`) to skip integrity verification for that model.

**Ad-hoc overrides** still work if needed:

```bash
flutter run \
  --dart-define=BREED_MODEL_URL=https://your-host.example/breed.tflite \
  --dart-define=BREED_MODEL_SHA256=<hex-digest>
```

### 4. Run the app

```bash
flutter run --dart-define-from-file=config/dev.json
```

On first launch, the app opens a startup screen and downloads any required real models before routing to onboarding or home. Downloaded models are cached in the app documents directory.

## Building

### Android APK (debug)

```bash
flutter build apk --debug --dart-define-from-file=config/dev.json
```

### Android APK (release)

```bash
flutter build apk --release --dart-define-from-file=config/prod.json
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android APK — split by ABI (smaller downloads)

```bash
flutter build apk --release --split-per-abi --dart-define-from-file=config/prod.json
```

Produces separate APKs for `arm64-v8a`, `armeabi-v7a`, and `x86_64`.

### Android App Bundle (Play Store)

```bash
flutter build appbundle --release --dart-define-from-file=config/prod.json
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS (simulator)

```bash
flutter build ios --simulator --dart-define-from-file=config/dev.json
```

### iOS (device / App Store)

```bash
flutter build ios --release --dart-define-from-file=config/prod.json
```

Requires a valid signing certificate and provisioning profile configured in Xcode.

## Scripts

Version management is handled by a single script:

```bash
# Bump version and commit
dart scripts/bump_version.dart {major|minor|patch|build}

# Bump version only (no git commit)
dart scripts/bump_version.dart patch --no-commit

# Bump with a custom commit message
dart scripts/bump_version.dart minor "chore: release v1.1.0 for QA"
```

Other scripts:

```bash
# Run the app (wraps flutter run with model flag helpers)
dart scripts/run.dart --use-placeholders
dart scripts/run.dart --breed-model-url https://example.com/breed.tflite

# Clean
dart scripts/clean.dart
```

## Testing

Run all tests:

```bash
flutter test
```

Run tests with coverage:

```bash
flutter test --coverage
```

## Project Structure

```
lib/
├── core/                  # App-wide utilities and config
│   ├── config/            # Runtime build-variable configuration
│   ├── constants/         # Shared layout constants
│   ├── error/             # Typed app exceptions
│   ├── router/            # GoRouter setup
│   ├── services/          # Core onboarding service
│   ├── theme/             # App theming
│   └── widgets/           # Shared widgets
├── features/              # Feature modules
│   ├── home/              # Home screen
│   ├── onboarding/        # Onboarding flow
│   ├── prediction/        # Breed and gender prediction
│   ├── results/           # Prediction history
│   ├── settings/          # Settings
│   └── startup/           # First-launch bootstrap and model preload
├── providers/             # Riverpod providers
├── services/              # Model download, TFLite, audio, camera, database
└── main.dart              # App entry point
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT License
