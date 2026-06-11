# Google Maps API Keys — Setup & Troubleshooting

## Overview

The app uses Google Maps in two ways:

| Feature | Runs via | API required |
|---|---|---|
| Map tiles (google_maps_flutter) | Native Maps SDK | **Maps SDK for Android** |
| Route polyline (Directions) | Dart HTTP call | **Directions API** |

Both use the **same API key** from `local.properties`.  
The key flows to Android via Gradle → AndroidManifest, and to Dart via Gradle → dart-define + native method-channel fallback.

---

## 1. Initial setup (one-time)

### 1a. Stable debug keystore

```bash
cd android
./gradlew generateDebugKeystore   # Windows: gradlew.bat generateDebugKeystore
```

Creates `app/debug.keystore` (alias: `androiddebugkey`, passwords: `android`).  
**Commit this file** so the debug SHA-1 never changes.

### 1b. Get your debug SHA-1

```bash
cd android
./gradlew signingReport
```

Under **Variant: debug**, copy the **SHA-1** fingerprint (e.g. `AB:CD:EF:...`).

---

## 2. Google Cloud Console — step by step

Open: <https://console.cloud.google.com/apis/credentials>

### 2a. Enable required APIs

Go to **APIs & Services → Library** and enable **both**:

- [x] **Directions API**
- [x] **Maps SDK for Android**

### 2b. Enable Billing

**APIs & Services → Billing** — attach a billing account.  
Directions API **requires** billing; without it every request returns `REQUEST_DENIED`.

### 2c. Create / edit your API key

Go to **APIs & Services → Credentials → API keys → (your key)**.

---

## 3. Quick Test (unrestricted — do this FIRST when debugging)

If you get `REQUEST_DENIED`, start here to isolate whether it's a restriction issue or an API-not-enabled issue.

1. Open the key in Cloud Console.
2. Set **Application restrictions** → **None**.
3. Set **API restrictions** → **Don't restrict key**.
4. Click **Save**.
5. **Wait 5 minutes** (Google propagation delay).
6. Re-run the app: `flutter run`
7. Check logs:

```
[Directions] response status=OK          ← success
[Directions] decoded polyline points=42
```

- **If OK** → the issue was restriction config. Proceed to Section 4 (Production restrictions).
- **If still REQUEST_DENIED** → the API is not enabled or billing is missing. Re-check 2a and 2b.

---

## 4. Production restrictions (apply AFTER Quick Test passes)

### Application restrictions → Android apps

Add **one entry** per build variant:

| Build | Package name | SHA-1 |
|---|---|---|
| Debug | `sa.gaseelexpress.courier.test` | From `./gradlew signingReport` (debug variant) |
| Release | `sa.gaseelexpress.courier.test` | Play App Signing SHA-1: `61:BF:46:35:45:CE:27:3E:76:1D:90:9E:67:21:2B:15:4D:41:FB:65` |

> **Warning:** If you set "HTTP referrers" or "IP addresses" instead of "Android apps", all mobile HTTP calls (including Directions) will fail with `REQUEST_DENIED`. Mobile apps must use **Android apps** restriction.

### API restrictions → Restrict key

Select **both**:

- [x] Directions API
- [x] Maps SDK for Android

Click **Save** and wait 5 minutes.

---

## 5. Put the key in `local.properties`

File: `android/local.properties` (git-ignored)

```properties
gms.debugApiKey=AIzaSy...YOUR_DEBUG_KEY
gms.releaseApiKey=AIzaSy...YOUR_RELEASE_KEY
```

You can use the same key for both if it has both debug and release SHA-1 entries.

The build system injects this key into:
- Android Manifest → Maps SDK (native tiles)
- Dart define → Directions API (Dart HTTP)

---

## 6. Build & verify

```bash
flutter run
```

No `--dart-define` needed. Expected debug logs:

```
[MapsConfig]   keySource=dart-define keyLoaded=true keyPreview=AIza****MEik
[Directions]   keySource=dart-define keyLoaded=true keyTail=MEik
[Directions]   origin=24.71360,46.67530 destination=24.71800,46.66800 waypoints=1
[Directions]   request: https://maps.googleapis.com/.../json?...&key=***KEY***
[Directions]   response status=OK error_message=null
[Directions]   decoded polyline points=42
```

---

## 7. Troubleshooting checklist

If `response status=REQUEST_DENIED`:

| # | Check | How to verify |
|---|---|---|
| 1 | **Correct key?** | Compare `keyTail` in logs with the last 4 chars of the key in Cloud Console. Must match. |
| 2 | **Directions API enabled?** | Cloud Console → APIs & Services → Library → search "Directions API" → must say "Enabled". |
| 3 | **Billing enabled?** | Cloud Console → Billing → project must have an active billing account. |
| 4 | **API restrictions include Directions?** | Key → API restrictions → "Directions API" must be checked. |
| 5 | **App restriction type?** | Must be "Android apps", NOT "HTTP referrers" or "IP addresses". |
| 6 | **Package name exact?** | Must be exactly `sa.gaseelexpress.courier.test` (no trailing space, no different suffix). |
| 7 | **SHA-1 matches?** | Run `cd android && ./gradlew signingReport`. Debug SHA-1 must match what's in Cloud Console. |
| 8 | **Propagation delay?** | After any Cloud Console change, wait **5 minutes** before retesting. |
| 9 | **Same GCP project?** | If you have multiple projects, ensure the key belongs to the project where APIs are enabled. |

### Quick isolation test

If all else fails:
1. Set restrictions to None / Don't restrict (Section 3).
2. If that works → restriction mismatch. Fix SHA-1 or package name.
3. If that still fails → API not enabled or billing issue.

---

## 8. Architecture: how the key reaches Dart

```
local.properties
  gms.debugApiKey = AIza...
         │
         ├─► build.gradle.kts
         │     ├─► manifestPlaceholders["MAPS_API_KEY"] ─► AndroidManifest.xml ─► Maps SDK
         │     │                                                      │
         │     │                                     MethodChannel "app.maps_config"
         │     │                                          (runtime fallback)
         │     │                                                      │
         │     └─► project.extra["dart-defines"] ─► String.fromEnvironment ─► MapsConfig
         │                                              (compile-time, primary)
         │
         └─► MapsConfig.getEffectiveApiKey() ─► DirectionsService
```

Both the Maps SDK and the Directions HTTP call always use the **same key**.
