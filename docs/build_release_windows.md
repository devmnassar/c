# Building Release AAB on Windows

Use this when the release build fails with file-lock errors (e.g. `FileSystemException: classes.dex ... being used by another process`).

## 1. Release file locks

1. **Close Android Studio** (and any IDE that has the project open).
2. **Stop any running app**: if you ran `flutter run`, stop it (Ctrl+C in the terminal).
3. **Clean and stop Gradle**:

   ```cmd
   flutter clean
   cd android && gradlew --stop && cd ..
   ```

4. **If locks persist**, kill processes that may hold build outputs (run in a **new** Command Prompt or PowerShell as needed):

   ```cmd
   taskkill /F /IM java.exe
   taskkill /F /IM dart.exe
   taskkill /F /IM gradle.exe
   taskkill /F /IM adb.exe
   adb start-server
   ```

5. **Antivirus (Windows Defender / Avast, etc.)**:  
   If locks continue, **exclude the project folder** from real-time scanning so it does not lock `build\` files during the build.

## 2. Build release AAB

From the **project root** (e.g. `gaseel_courier`):

```cmd
flutter clean
flutter pub get
flutter build appbundle --release
```

## 3. Output

- AAB path: `build\app\outputs\bundle\release\app-release.aab`  
  (relative to project root: `build/app/outputs/bundle/release/app-release.aab`)

## 4. Version code

- Bump the build number in `pubspec.yaml` (the number after `+`) before each new upload.  
- Google Play requires a **unique version code** per AAB upload.

## 5. Install conflicts (Play vs debug)

Before installing a build from Google Play (internal testing) on a device that had a debug build:

```cmd
adb uninstall sa.gaseelexpress.courier.test
```

Then install the Play build. This avoids conflicts between debug and release signing.
