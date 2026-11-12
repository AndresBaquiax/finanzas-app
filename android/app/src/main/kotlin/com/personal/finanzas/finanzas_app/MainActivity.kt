package com.personal.finanzas.finanzas_app

import android.Manifest
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL_NAME = "com.personal.finanzas/payment_detector"
        private const val SMS_PERMISSION_REQUEST_CODE = 4102
    }

    private var methodChannel: MethodChannel? = null
    private var pendingSmsResult: MethodChannel.Result? = null
    private var smsRequestStartTime: Long = 0L

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        methodChannel = channel

        PaymentDetectorStore.liveListener = { eventMap ->
            val currentChannel = methodChannel
            if (currentChannel != null) {
                currentChannel.invokeMethod("onPaymentDetected", eventMap)
                true
            } else {
                false
            }
        }

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermissions" -> {
                    result.success(getPermissionsMap())
                }
                "openNotificationListenerSettings" -> {
                    val opened = openNotificationAccessSettings()
                    result.success(opened)
                }
                "openAppDetailsSettings" -> {
                    val opened = openAppDetails()
                    result.success(opened)
                }
                "requestSmsPermission" -> {
                    if (isSmsPermissionGranted()) {
                        result.success(true)
                    } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        pendingSmsResult = result
                        smsRequestStartTime = System.currentTimeMillis()
                        requestPermissions(
                            arrayOf(
                                Manifest.permission.RECEIVE_SMS,
                                Manifest.permission.READ_SMS
                            ),
                            SMS_PERMISSION_REQUEST_CODE
                        )
                    } else {
                        result.success(true)
                    }
                }
                "consumeQueuedPayments" -> {
                    val events = PaymentDetectorStore.consumeQueuedEvents(applicationContext)
                    result.success(events)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        methodChannel?.invokeMethod("onPermissionsUpdated", getPermissionsMap())
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        PaymentDetectorStore.liveListener = null
        methodChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == SMS_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() &&
                grantResults.any { it == PackageManager.PERMISSION_GRANTED }
            val elapsed = System.currentTimeMillis() - smsRequestStartTime

            // If Android/MIUI blocked the dialog immediately (< 250ms), open App Info settings
            if (!granted && elapsed < 250L) {
                openAppDetails()
            }

            pendingSmsResult?.success(granted)
            pendingSmsResult = null
            methodChannel?.invokeMethod("onPermissionsUpdated", getPermissionsMap())
        }
    }

    private fun getPermissionsMap(): Map<String, Boolean> {
        return mapOf(
            "notificationAccess" to isNotificationListenerEnabled(),
            "smsPermission" to isSmsPermissionGranted()
        )
    }

    private fun openNotificationAccessSettings(): Boolean {
        val component = ComponentName(this, PaymentNotificationService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val detailIntent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS).apply {
                    putExtra(
                        Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME,
                        component.flattenToString()
                    )
                }
                startActivity(detailIntent)
                return true
            } catch (_: Exception) {
            }
        }
        return try {
            val listIntent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
            startActivity(listIntent)
            true
        } catch (_: Exception) {
            openAppDetails()
        }
    }

    private fun openAppDetails(): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
            }
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val component = ComponentName(this, PaymentNotificationService::class.java)
        val flat = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        ) ?: return false
        return flat.contains(component.flattenToString()) || flat.contains(packageName)
    }

    private fun isSmsPermissionGranted(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            checkSelfPermission(Manifest.permission.RECEIVE_SMS) ==
                PackageManager.PERMISSION_GRANTED ||
                checkSelfPermission(Manifest.permission.READ_SMS) ==
                PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }
}
