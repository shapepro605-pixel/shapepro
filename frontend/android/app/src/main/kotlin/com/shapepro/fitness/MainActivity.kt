package com.shapepro.fitness

import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.shapepro.fitness/health"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openHealthConnectSettings") {
                val intent = Intent("android.health.connect.action.MANAGE_HEALTH_PERMISSIONS")
                intent.putExtra(Intent.EXTRA_PACKAGE_NAME, packageName)
                try {
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    val intent2 = Intent("androidx.health.ACTION_HEALTH_CONNECT_SETTINGS")
                    try {
                        startActivity(intent2)
                        result.success(true)
                    } catch (e2: Exception) {
                        result.error("ERROR", "Could not open Health Connect settings", e2.message)
                    }
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
