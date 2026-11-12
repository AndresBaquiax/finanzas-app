package com.personal.finanzas.finanzas_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony

class PaymentSmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return

        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        if (messages.isNullOrEmpty()) return

        val sender = messages.firstOrNull()?.displayOriginatingAddress ?: "SMS Bancario"
        val fullBody = StringBuilder()
        for (msg in messages) {
            msg.displayMessageBody?.let { fullBody.append(it) }
        }
        val bodyStr = fullBody.toString()

        if (!PaymentDetectorStore.looksLikePayment("sms", sender, bodyStr)) return

        PaymentDetectorStore.recordOrDispatch(
            context = context.applicationContext,
            source = "bank_sms",
            packageName = "sms",
            title = sender,
            body = bodyStr,
            timestamp = System.currentTimeMillis()
        )
    }
}
