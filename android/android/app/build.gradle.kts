import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(localPropertiesFile.inputStream())
}
// Fallback key so Maps never get empty key (blank tiles). Replace with your key; restrict in Google Cloud.
val mapsKeyFallback = "AIzaSyBBuYq5fqNGpxADCFjJsF6CGB_pumMPEik"
val mapsDebugKey = localProperties.getProperty("gms.debugApiKey", mapsKeyFallback)
val mapsReleaseKey = localProperties.getProperty("gms.releaseApiKey", mapsKeyFallback)

// ──────────────────────────────────────────────────────────────────────
// Auto-inject MAPS_API_KEY into Flutter dart-defines from local.properties.
// This makes the Directions API (Dart HTTP) use the SAME key as the Maps SDK
// (Android Manifest) without needing manual --dart-define=MAPS_API_KEY=...
//
// How it works:
//   • Flutter Gradle Plugin reads "dart-defines" project property.
//   • When no --dart-define is passed on CLI, project.findProperty returns
//     null, so we inject it via project.extra.
//   • If the user explicitly passes --dart-define=MAPS_API_KEY=xxx, the CLI
//     property takes precedence and our extra property is ignored — which is
//     the correct behavior.
//
// Limitation: this injects the debug key at configuration time (we cannot
// distinguish build type here). For release builds, the runtime fallback
// in MapsConfig reads the actual key from AndroidManifest via method channel
// (which IS variant-aware and always matches the Maps SDK key).
// ──────────────────────────────────────────────────────────────────────
run {
    val existingDefines = (project.findProperty("dart-defines") as? String) ?: ""

    // Check if MAPS_API_KEY was already provided (via --dart-define on CLI)
    val keyAlreadyProvided = existingDefines.split(",")
        .filter { it.isNotBlank() }
        .any { encoded ->
            try {
                String(Base64.getDecoder().decode(encoded.trim()))
                    .startsWith("MAPS_API_KEY=")
            } catch (_: Exception) { false }
        }

    if (!keyAlreadyProvided) {
        val mapsKeyForDart = mapsReleaseKey
        val encoded = Base64.getEncoder()
            .encodeToString("MAPS_API_KEY=$mapsKeyForDart".toByteArray())
        val merged = if (existingDefines.isBlank()) encoded
                     else "$existingDefines,$encoded"
        project.extra["dart-defines"] = merged
    }
}

val hasValidReleaseKeystore = keystorePropertiesFile.exists() &&
    keystoreProperties["storePassword"]?.toString().isNullOrBlank().not() &&
    keystoreProperties["keyPassword"]?.toString().isNullOrBlank().not() &&
    keystoreProperties["keyAlias"]?.toString().isNullOrBlank().not() &&
    keystoreProperties["storeFile"]?.toString().isNullOrBlank().not()

val debugKeystoreFile = file("debug.keystore")

android {
    namespace = "sa.gaseelexpress.courier.test"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    useLibrary("org.apache.http.legacy")
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    packaging {
        jniLibs {
            // Standard AGP 8+ packaging for Flutter.
        }
    }


    defaultConfig {
        applicationId = "sa.gaseelexpress.courier.test"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["MAPS_API_KEY"] = "" // overridden per buildType
    }

    signingConfigs {
        if (debugKeystoreFile.exists()) {
            getByName("debug") {
                storeFile = debugKeystoreFile
                storePassword = "android"
                keyAlias = "androiddebugkey"
                keyPassword = "android"
            }
        }
        if (hasValidReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"].toString()
                keyPassword = keystoreProperties["keyPassword"].toString()
                storeFile = file(keystoreProperties["storeFile"].toString())
                storePassword = keystoreProperties["storePassword"].toString()
            }
        }
    }

    buildTypes {
        getByName("debug") {
            manifestPlaceholders["MAPS_API_KEY"] = mapsDebugKey
            if (debugKeystoreFile.exists()) {
                signingConfig = signingConfigs.getByName("debug")
            }
        }
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            manifestPlaceholders["MAPS_API_KEY"] = mapsReleaseKey
            if (hasValidReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                throw GradleException(
                    "Release build requires android/key.properties with storePassword, keyPassword, keyAlias, storeFile. " +
                    "Create key.properties and upload-keystore.jks for release signing. See: https://docs.flutter.dev/deployment/android"
                )
            }
        }
    }
}

dependencies {
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.gms:play-services-maps:19.0.0")
}

flutter {
    source = "../.."
}

tasks.matching { it.name.endsWith("MainManifest") }.configureEach {
    // Work around Gradle state-tracking failures on Windows when AGP does not
    // materialize the manifest merge blame file early enough.
    doNotTrackState("Manifest merge blame file is generated lazily on this setup")
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}
