package com.djk.opener

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

/**
 * Service d'accessibilite qui surveille les changements de fenetre au
 * premier plan. Des qu'une application presente dans la liste bloquee
 * (definie par le parent dans DJK Opener) passe au premier plan, on
 * affiche l'ecran de blocage natif (BlockActivity) par-dessus.
 */
class MonitorAccessibilityService : AccessibilityService() {

    override fun onServiceConnected() {
        super.onServiceConnected()
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.DEFAULT
            notificationTimeout = 100
        }
        serviceInfo = info
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val packageName = event?.packageName?.toString() ?: return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        // Ignore nos propres ecrans pour ne pas se bloquer soi-meme
        if (packageName == applicationContext.packageName) return

        val blocked = SecureStore.getBlockedPackages(applicationContext)
        if (blocked.contains(packageName)) {
            val intent = Intent(this, BlockActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra("blocked_package", packageName)
            }
            startActivity(intent)
        }
    }

    override fun onInterrupt() {
        // Rien a faire
    }
}
