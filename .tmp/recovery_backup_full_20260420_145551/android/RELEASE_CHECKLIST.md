# Android Release Checklist (Google Play AAB)

## 1. Signing setup (already configured)

- **key.properties**: `android/key.properties` (exists; **do not commit** — in `.gitignore`).
- **Keystore**: `android/app/upload-keystore.jks` (exists; **do not commit** — `**/*.jks` in `.gitignore`).
- **Template**: Copy `android/key.properties.example` to `key.properties` and fill with your keystore values.

## 2. Gradle config (validated)

- **Release signing**: `release` buildType uses `signingConfigs.release` from `key.properties`.
- **minifyEnabled**: `false` (can enable later).
- **compileSdk / targetSdk**: From Flutter SDK (no change).
- **Packaging**: `jniLibs.useLegacyPackaging = true` and `keepDebugSymbols += "**/*.so"` to avoid strip-debug-symbols issues on Windows.

## 3. Versioning

- **pubspec.yaml**: `version: 1.0.1+9` → **versionName** `1.0.1`, **versionCode** `9`.
- Bump before each Play upload: increment `+N` (versionCode) or the semantic part (versionName).

## 4. Application ID / package

- **applicationId**: `sa.gaseelexpress.courier.test`
- **namespace**: `sa.gaseelexpress.courier.test`
- **AndroidManifest**: Uses `${MAPS_API_KEY}` from build (release uses `gms.releaseApiKey` from `local.properties`).

## 5. Build commands

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

**Output AAB**: `build/app/outputs/bundle/release/app-release.aab`

## 6. RELEASE certificate SHA-1 and SHA-256

Run locally (you will be prompted for the keystore password):

```bash
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload
```

From the output, copy:

- **SHA1**: (e.g. `AA:BB:CC:...`)
- **SHA-256**: (e.g. `AA:BB:CC:...`)

**Google Maps**: Add the **RELEASE SHA-1** (and SHA-256 if required) in Google Cloud Console (APIs & Services → Credentials) so Maps and other APIs work for the release build.

## 7. Files to NOT commit

- `android/key.properties`
- `android/app/upload-keystore.jks` (and any other `*.jks` / `*.keystore` except `app/debug.keystore` if you use it)
- `android/local.properties` (SDK path; already in `.gitignore`)

## 8. Warnings / known issues

- **Strip debug symbols (Windows)**: If you see *"Release app bundle failed to strip debug symbols from native libraries"*, it is a known Windows/AGP issue. Options:
  - Build on macOS/Linux or in CI.
  - Or use WSL and run the same Flutter build commands there.
- **JDK**: Use a supported JDK (e.g. 17) for the Android toolchain.

## 9. Final checklist before upload

- [ ] `key.properties` exists under `android/` and is **not** committed.
- [ ] Keystore `android/app/upload-keystore.jks` exists and is **not** committed.
- [ ] `version` in `pubspec.yaml` bumped (versionCode incremented for each upload).
- [ ] `flutter build appbundle --release` succeeds.
- [ ] AAB path: `build/app/outputs/bundle/release/app-release.aab`.
- [ ] RELEASE SHA-1 (and SHA-256) added in Google Cloud for this applicationId.
- [ ] `local.properties` has `gms.releaseApiKey` set if you use a separate release Maps key.
