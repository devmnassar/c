package sa.gaseelexpress.courier.test

import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import com.google.android.gms.maps.MapsInitializer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity : FlutterActivity() {


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.locale").setMethodCallHandler { call, result ->
            when (call.method) {
                "setLocale" -> {
                    val lang = call.argument<String>("lang") ?: "en"
                    Log.i("AppLocale", "Flutter locale changed to: $lang")
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.diagnostics").setMethodCallHandler { call, result ->
            when (call.method) {
                "getPackageName" -> result.success(applicationContext.packageName)
                "getSigningCertSha1" -> result.success(getAppSigningSha1())
                "getMetaDataValue" -> {
                    val key = call.argument<String>("key") ?: ""
                    val value = getMetaDataValueMasked(key)
                    result.success(value)
                }
                else -> result.notImplemented()
            }
        }
        // Provides the Maps API key from AndroidManifest to Flutter.
        // This is the same key the Maps SDK uses (variant-aware: debug vs release).
        // Flutter falls back to this when --dart-define=MAPS_API_KEY is not set.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.maps_config").setMethodCallHandler { call, result ->
            when (call.method) {
                "getApiKey" -> {
                    val key = try {
                        applicationContext.packageManager
                            .getApplicationInfo(applicationContext.packageName, PackageManager.GET_META_DATA)
                            .metaData?.getString("com.google.android.geo.API_KEY") ?: ""
                    } catch (e: Exception) {
                        Log.w("GaseelMaps", "getApiKey failed", e)
                        ""
                    }
                    result.success(key)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getMetaDataValueMasked(key: String): String? {
        return try {
            val raw = applicationContext.packageManager
                .getApplicationInfo(applicationContext.packageName, PackageManager.GET_META_DATA)
                .metaData?.getString(key) ?: return null
            if (key == "com.google.android.geo.API_KEY" && raw.length >= 8) {
                "${raw.take(4)}****${raw.takeLast(4)}"
            } else {
                raw
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun logGaseelMapsDiagnostics() {
        val tag = "GaseelMaps"

        // 1) Runtime package name (applicationId) — must match Google Cloud key restriction
        val packageName = applicationContext.packageName
        Log.i(tag, "applicationId=$packageName")

        // 2) Build type (debug/release) — use for key restriction / SHA-1
        val isDebug = (applicationContext.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        Log.i(tag, "buildType=${if (isDebug) "debug" else "release"}")

        // 3) Manifest meta-data for com.google.android.geo.API_KEY (first 6 chars only)
        val apiKey = try {
            applicationContext.packageManager
                .getApplicationInfo(packageName, PackageManager.GET_META_DATA)
                .metaData?.getString("com.google.android.geo.API_KEY")
        } catch (e: Exception) {
            null
        }
        if (apiKey.isNullOrBlank()) {
            Log.w(tag, "com.google.android.geo.API_KEY meta-data: (missing or empty - not in merged manifest)")
        } else {
            val masked = if (apiKey.length >= 6) "${apiKey.take(6)}****" else "****"
            Log.i(tag, "com.google.android.geo.API_KEY meta-data: $masked (present in merged manifest)")
        }

        // 4) App signing certificate SHA-1 at runtime — must match Google Cloud key restriction
        val sha1 = getAppSigningSha1()
        if (sha1 != null) {
            Log.i(tag, "app_signing_sha1=$sha1")
        } else {
            Log.w(tag, "app_signing_sha1=(unable to read)")
        }

        // 5) Maps initialization status / errors
        try {
            MapsInitializer.initialize(applicationContext)
            Log.i(tag, "MapsInitializer: OK")
        } catch (e: Exception) {
            Log.e(tag, "MapsInitializer: FAIL", e)
            Log.e(tag, "MapsInitializer message: ${e.message}")
            val cause = e.cause
            if (cause != null) {
                Log.e(tag, "MapsInitializer cause: ${cause.javaClass.simpleName} ${cause.message}")
            }
        }
    }

    private fun getAppSigningSha1(): String? {
        return try {
            val pm = applicationContext.packageManager
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                PackageManager.GET_SIGNING_CERTIFICATES
            } else {
                @Suppress("DEPRECATION")
                PackageManager.GET_SIGNATURES
            }
            val info = pm.getPackageInfo(applicationContext.packageName, flags)
            val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                info.signingInfo?.apkContentsSigners
            } else {
                @Suppress("DEPRECATION")
                info.signatures
            }
            val sig = signatures?.firstOrNull() ?: return null
            val md = MessageDigest.getInstance("SHA-1")
            val digest = md.digest(sig.toByteArray())
            digest.joinToString("") { "%02x".format(it) }
        } catch (e: Exception) {
            Log.w("GaseelMaps", "getAppSigningSha1", e)
            null
        }
    }
}
