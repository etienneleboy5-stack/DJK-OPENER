package com.djk.opener

import android.content.Context

/**
 * Stockage partage entre l'UI Flutter (via MainActivity) et le service
 * d'accessibilite qui tourne en arriere-plan. On utilise un fichier
 * SharedPreferences dedie pour ne dependre d'aucun plugin tiers.
 */
object SecureStore {
    private const val PREFS_NAME = "djk_opener_secure"
    private const val KEY_PIN_HASH = "pin_hash"
    private const val KEY_BLOCKED_PACKAGES = "blocked_packages"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun getPinHash(context: Context): String? =
        prefs(context).getString(KEY_PIN_HASH, null)

    fun savePinHash(context: Context, hash: String) {
        prefs(context).edit().putString(KEY_PIN_HASH, hash).apply()
    }

    fun getBlockedPackages(context: Context): Set<String> =
        prefs(context).getStringSet(KEY_BLOCKED_PACKAGES, emptySet()) ?: emptySet()

    fun saveBlockedPackages(context: Context, packages: Set<String>) {
        prefs(context).edit().putStringSet(KEY_BLOCKED_PACKAGES, packages).apply()
    }
}

/**
 * Liste des reseaux sociaux courants reconnus par l'application.
 */
object KnownSocialApps {
    val MAP: Map<String, String> = linkedMapOf(
        "com.facebook.katana" to "Facebook",
        "com.facebook.lite" to "Facebook Lite",
        "com.instagram.android" to "Instagram",
        "com.instagram.lite" to "Instagram Lite",
        "com.whatsapp" to "WhatsApp",
        "com.whatsapp.w4b" to "WhatsApp Business",
        "com.zhiliaoapp.musically" to "TikTok",
        "com.ss.android.ugc.trill" to "TikTok",
        "com.twitter.android" to "X (Twitter)",
        "com.snapchat.android" to "Snapchat",
        "com.google.android.youtube" to "YouTube",
        "com.discord" to "Discord",
        "com.pinterest" to "Pinterest",
        "com.linkedin.android" to "LinkedIn",
        "org.telegram.messenger" to "Telegram",
        "com.reddit.frontpage" to "Reddit"
    )
}
