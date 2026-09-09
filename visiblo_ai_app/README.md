# VisibloAI Mobile App

Flutter client for VisibloAI. The application uses GetX, Dio, Firebase,
Google Sign-In, Razorpay, secure token storage, and connectivity-aware API
recovery.

## Requirements

- Flutter matching the SDK constraint in `pubspec.yaml`
- Java 17 and Android Studio for Android builds
- Xcode and CocoaPods for iOS builds
- Valid Firebase Android/iOS configuration files
- Access to the selected VisibloAI API environment

## Setup

```bash
flutter pub get
flutter analyze
flutter test
```

Run against production (the default):

```bash
flutter run \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://app.visibloai.com/api
```

Run against development or staging by providing its HTTPS endpoint:

```bash
flutter run \
  --dart-define=APP_ENV=staging \
  --dart-define=API_BASE_URL=https://YOUR-STAGING-HOST/api
```

Release builds reject non-HTTPS API URLs. Do not place server secrets in
`--dart-define`; values compiled into a mobile application are recoverable.

## Validation

Before merging a release candidate, run:

```bash
flutter analyze
flutter test
flutter build appbundle --release \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://app.visibloai.com/api
```

Format every Dart file you change with `dart format` before running validation.
CI enforces formatting for the production bootstrap/configuration files and the
test suite, in addition to analysis, tests, and the release build.

Use an Android App Bundle for Play Store delivery. The universal APK is useful
for local testing but is much larger than the device-specific downloads served
from an AAB.

## Android signing

Create an upload keystore outside source control and configure
`android/key.properties`. Never commit the JKS or its passwords. Release signing
must replace the current debug-signing placeholder before store submission.

Recommended ignored files:

```text
android/key.properties
android/app/*.jks
android/app/*.keystore
```

Keep two encrypted backups of the upload key and credentials.

## Android Play publishing

This project is configured for Gradle Play Publisher. The default publishing
track is `internal`, and the Play upload uses Android App Bundles.

Prerequisites:

1. The app must already exist in Play Console for `com.example.visiblo_ai_app`.
2. `android/key.properties` must point to the Play upload keystore.
3. A Play Console service account must have release access for this app.
4. Provide credentials either as `ANDROID_PUBLISHER_CREDENTIALS` or as the
   ignored file `android/play-service-account.json`.

Build a signed bundle:

```bash
flutter build appbundle --release \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://app.visibloai.com/api
```

Publish to internal testing:

```bash
cd android
./gradlew publishBundle -PplayTrack=internal
```

Use `-PplayTrack=production` only after internal testing, device checks, and
Crashlytics/App Check monitoring look healthy.

## Firebase production checklist

Firebase client configuration files and API keys identify the Firebase project;
they are not server secrets. Security must be enforced in Firebase and Google
Cloud Console:

1. Register the final Android application ID and iOS bundle identifier.
2. Add Play upload/release SHA-1 and SHA-256 certificate fingerprints.
3. Restrict Firebase/Google API keys to the exact apps and required APIs.
4. Enable Play Integrity for Android App Check and App Attest for iOS.
5. Verify App Check metrics, then enforce App Check for supported Firebase APIs.
6. Review Firestore, Realtime Database, and Storage rules with the emulator/test suite.
7. Verify Google OAuth redirect URIs and consent-screen production status.
8. Confirm Crashlytics receives a non-fatal test event from internal builds.

App Check providers are activated by the client in release builds, but console
registration and enforcement are external deployment steps.

## Monitoring and privacy

- Crashlytics collection is enabled only in release builds.
- Flutter framework and uncaught platform errors are captured as fatal events.
- `debugPrint` output is disabled in release builds to prevent logs containing
  user or backend data.
- Authentication tokens are stored with `flutter_secure_storage`.

Do not add raw API payloads, access tokens, emails, or personal information to
monitoring metadata.

## Release procedure

1. Pull the latest `main` and resolve dependency changes.
2. Update `version` in `pubspec.yaml` with a unique build number.
3. Run formatting, analysis, tests, and a signed release AAB build.
4. Test login, Google OAuth, connectivity switching, payments, uploads,
   notifications, account deletion, and deep links on physical Android/iOS devices.
5. Upload to an internal testing track and review Crashlytics/App Check metrics.
6. Promote gradually and monitor authentication, payment, and API failure rates.

Production releases must not proceed while CI is failing.
