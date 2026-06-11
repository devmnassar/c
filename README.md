# gaseel_courier

A Flutter courier app with Google Maps (order details).

## Getting Started

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Flutter documentation](https://docs.flutter.dev/)

---

## Running release on device

To run a **release** build on a connected Android device (to reproduce blank map / tile issues):

```bash
flutter run --release
```

To build a release App Bundle for Play Store:

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

---

## Capturing logs (Google Maps / API key / billing)

With the app running (debug or release), capture Android logs:

```bash
adb logcat
```

**Useful filters** when debugging blank tiles or auth failures:

```bash
adb logcat -s "GaseelMaps" "GaseelError" "OrderDetailMap"
adb logcat | findstr /i "Google Maps AuthFailure Billing \"API key not authorized\""
```

(On macOS/Linux use `grep` instead of `findstr`.)

Save logs to a file:

```bash
adb logcat -s "GaseelMaps" "Google Android Maps SDK" > maps_log.txt
```

---

## Checklist: Maps SDK, billing, API key restrictions

If the map is **blank or gray** in release (especially when installed from Play Store), verify:

1. **Maps SDK for Android**  
   - Google Cloud Console → APIs & Services → Enabled APIs  
   - Ensure **Maps SDK for Android** is enabled for the project.

2. **Billing**  
   - Billing is linked to the same Google Cloud project used by the API key.  
   - Without billing, map tiles may not load in production.

3. **API key restrictions (Android)**  
   - Google Cloud Console → APIs & Services → Credentials → your API key.  
   - **Application restrictions** → Android apps.  
   - Add:
     - **Package name:** `sa.gaseelexpress.courier.test`
     - **SHA-1:**  
       - **Upload key** (from your upload keystore / Play Console → Upload key certificate).  
       - **Play App Signing SHA-1** (Play Console → Your app → Setup → App signing → App signing key certificate).  
   - For apps installed from Play, the runtime certificate is the **App Signing** key; that SHA-1 must be in the key restrictions.
# Ghassel-Ui
