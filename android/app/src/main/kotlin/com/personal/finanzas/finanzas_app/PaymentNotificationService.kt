package com.personal.finanzas.finanzas_app

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class PaymentNotificationService : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null || sbn.isOngoing) return
        val pkg = sbn.packageName ?: return
        if (pkg == applicationContext.packageName) return

        val extras = sbn.notification?.extras ?: return
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
        val body = if (bigText.length > text.length) bigText else text

        if (!PaymentDetectorStore.looksLikePayment(pkg, title, body)) return

        val isWallet = pkg.contains("wallet") ||
            pkg.contains("tapandpay") ||
            title.lowercase().contains("wallet") ||
            title.lowercase().contains("billetera") ||
            title.lowercase().contains("g pay")

        val source = if (isWallet) "google_wallet" else "bank_notification"

        PaymentDetectorStore.recordOrDispatch(
            context = applicationContext,
            source = source,
            packageName = pkg,
            title = title,
            body = body,
            timestamp = sbn.postTime
        )
    }
}
