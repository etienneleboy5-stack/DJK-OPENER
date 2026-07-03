package com.djk.opener

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity : FlutterActivity() {

    private val CHANNEL = "djk_opener/native"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isPinSet" -> result.success(SecureStore.getPinHash(this) != null)

                "setPin" -> {
                    val pin = call.argument<String>("pin") ?: ""
                    SecureStore.savePinHash(this, sha256(pin))
                    result.success(true)
                }

                "verifyPin" -> {
                    val pin = call.argument<String>("pin") ?: ""
                    val stored = SecureStore.getPinHash(this)
                    result.success(stored != null && stored == sha256(pin))
                }

                "getKnownApps" -> result.success(getKnownAppsList())

                "setAppBlocked" -> {
                    val pkg = call.argument<String>("package") ?: ""
                    val blocked = call.argument<Boolean>("blocked") ?: false
                    val current = SecureStore.getBlockedPackages(this).toMutableSet()
                    if (blocked) current.add(pkg) else current.remove(pkg)
                    SecureStore.saveBlockedPackages(this, current)
                    result.success(true)
                }

                "isAccessibilityEnabled" -> result.success(isAccessibilityServiceEnabled())

                "openAccessibilitySettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun sha256(text: String): String {
        val bytes = MessageDigest.getInstance("SHA-256").digest(text.toByteArray())
        return bytes.joinToString("") { "%02x".format(it) }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val am = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabledServices = am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
        return enabledServices.any {
            it.resolveInfo.serviceInfo.packageName == packageName &&
                it.resolveInfo.serviceInfo.name == MonitorAccessibilityService::class.java.name
        }
    }

    private fun getKnownAppsList(): List<Map<String, Any>> {
        val blocked = SecureStore.getBlockedPackages(this)
        val pm = packageManager
        val result = mutableListOf<Map<String, Any>>()

        for ((pkg, name) in KnownSocialApps.MAP) {
            try {
                pm.getPackageInfo(pkg, 0)
                result.add(
                    mapOf(
                        "package" to pkg,
                        "name" to name,
                        "installed" to true,
                        "blocked" to blocked.contains(pkg)
                    )
                )
            } catch (e: PackageManager.NameNotFoundException) {
                // App non installee : on ne l'affiche pas
            }
        }
        return result
    }
}
