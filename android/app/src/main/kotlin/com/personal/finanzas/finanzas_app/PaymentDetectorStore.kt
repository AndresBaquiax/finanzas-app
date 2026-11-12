package com.personal.finanzas.finanzas_app

import android.content.Context
import android.os.Handler
import android.os.Looper
import org.json.JSONArray
import org.json.JSONObject

object PaymentDetectorStore {
    private const val PREFS_NAME = "finanzas_native_payment_detector"
    private const val KEY_QUEUE = "pending_payment_events_v1"
    private const val MAX_QUEUE_SIZE = 50

    private val mainHandler = Handler(Looper.getMainLooper())
    var liveListener: ((Map<String, Any?>) -> Boolean)? = null

    private var lastSignature: String = ""
    private var lastTimestamp: Long = 0L

    private val paymentKeywords = listOf(
        "consumo",
        "compra",
        "pagaste",
        "pago realizado",
        "pago con",
        "cargo",
        "debito",
        "débito",
        "transaccion",
        "transacción",
        "aprobada",
        "aprobado",
        "autorizada",
        "autorizado",
        "google wallet",
        "g pay",
        "billetera",
        "gtq",
        "usd",
        "quetzales",
        "dolares",
        "dólares"
    )

    private val walletPackages = setOf(
        "com.google.android.apps.walletnfcrel",
        "com.google.commerce.tapandpay.android.card.app"
    )

    fun looksLikePayment(packageName: String, title: String, body: String): Boolean {
        val combined = "$title $body".lowercase()
        val hasDigits = combined.any { it.isDigit() }
        if (!hasDigits) return false

        // Ignore verification codes / OTPs
        if (combined.contains("codigo de verificacion") ||
            combined.contains("código de verificación") ||
            combined.contains("otp") ||
            combined.contains("token de seguridad") ||
            combined.contains("clave temporal")
        ) {
            return false
        }

        if (walletPackages.contains(packageName)) {
            return true
        }

        if (packageName == "com.google.android.gms" &&
            (combined.contains("wallet") || combined.contains("billetera") || combined.contains("g pay"))
        ) {
            return true
        }

        val hasCurrencySymbol = Regex("""(?i)(\bgtq\b|\busd\b|q\.?\s*\d|\$\s*\d)""").containsMatchIn(combined)
        val hasKeyword = paymentKeywords.any { combined.contains(it) }

        return hasCurrencySymbol && hasKeyword
    }

    @Synchronized
    fun recordOrDispatch(
        context: Context,
        source: String,
        packageName: String,
        title: String,
        body: String,
        timestamp: Long = System.currentTimeMillis()
    ) {
        val cleanTitle = title.trim()
        val cleanBody = body.trim()
        if (cleanTitle.isEmpty() && cleanBody.isEmpty()) return

        val signature = "$source|$packageName|$cleanTitle|$cleanBody"
        if (signature == lastSignature && (timestamp - lastTimestamp) < 6000L) {
            return
        }
        lastSignature = signature
        lastTimestamp = timestamp

        val map = mapOf<String, Any?>(
            "id" to "det_${timestamp}_${(100..999).random()}",
            "source" to source,
            "packageName" to packageName,
            "title" to cleanTitle,
            "body" to cleanBody,
            "timestamp" to timestamp
        )

        mainHandler.post {
            val handledLive = try {
                liveListener?.invoke(map) ?: false
            } catch (_: Exception) {
                false
            }
            if (!handledLive) {
                enqueueToPrefs(context.applicationContext, map)
            }
        }
    }

    @Synchronized
    private fun enqueueToPrefs(context: Context, map: Map<String, Any?>) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val raw = prefs.getString(KEY_QUEUE, "[]") ?: "[]"
            val arr = JSONArray(raw)
            val obj = JSONObject()
            for ((k, v) in map) {
                obj.put(k, v)
            }
            arr.put(obj)

            val trimmed = JSONArray()
            val start = if (arr.length() > MAX_QUEUE_SIZE) arr.length() - MAX_QUEUE_SIZE else 0
            for (i in start until arr.length()) {
                trimmed.put(arr.getJSONObject(i))
            }
            prefs.edit().putString(KEY_QUEUE, trimmed.toString()).apply()
        } catch (_: Exception) {
        }
    }

    @Synchronized
    fun consumeQueuedEvents(context: Context): List<Map<String, Any?>> {
        val result = mutableListOf<Map<String, Any?>>()
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val raw = prefs.getString(KEY_QUEUE, "[]") ?: "[]"
            val arr = JSONArray(raw)
            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                result.add(
                    mapOf(
                        "id" to obj.optString("id"),
                        "source" to obj.optString("source"),
                        "packageName" to obj.optString("packageName"),
                        "title" to obj.optString("title"),
                        "body" to obj.optString("body"),
                        "timestamp" to obj.optLong("timestamp", System.currentTimeMillis())
                    )
                )
            }
            prefs.edit().remove(KEY_QUEUE).apply()
        } catch (_: Exception) {
        }
        return result
    }
}
