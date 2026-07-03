package com.djk.opener

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import android.widget.Toast
import java.security.MessageDigest

/**
 * Ecran affiche par-dessus une application bridee. Message transparent :
 * on explique clairement que l'app est bridee par DJK Opener et qu'il
 * faut le code du parent pour la debloquer -- pas de faux bouton cache,
 * pas de mot de passe partage.
 *
 * NOTE : herite de Activity (pas AppCompatActivity) car BlockTheme est
 * un theme systeme classique (Theme.Black.NoTitleBar) et non un theme
 * AppCompat -- melanger les deux provoque un crash au demarrage.
 */
class BlockActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_block)
        afficherMessagePour(intent.getStringExtra("blocked_package"))
        configurerBoutons()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        afficherMessagePour(intent.getStringExtra("blocked_package"))
    }

    private fun afficherMessagePour(appBloquee: String?) {
        val sousTitre = findViewById<TextView>(R.id.txt_sous_titre)
        val nomAffiche = KnownSocialApps.MAP[appBloquee] ?: appBloquee ?: "cette application"
        sousTitre.text = "\"$nomAffiche\" a ete bride par DJK Opener.\n" +
            "Merci d'attendre qu'un parent vous autorise l'acces."
    }

    private fun configurerBoutons() {
        findViewById<Button>(R.id.btn_accueil).setOnClickListener {
            val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(homeIntent)
            finish()
        }

        val champPin = findViewById<EditText>(R.id.champ_pin)
        findViewById<Button>(R.id.btn_code_parent).setOnClickListener {
            val pin = champPin.text.toString().trim()
            val stored = SecureStore.getPinHash(applicationContext)
            if (stored != null && pin.isNotEmpty() && stored == sha256(pin)) {
                val ouvrirApp = Intent(this, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                }
                startActivity(ouvrirApp)
                finish()
            } else {
                Toast.makeText(this, "Code incorrect.", Toast.LENGTH_SHORT).show()
                champPin.text.clear()
            }
        }
    }

    private fun sha256(text: String): String {
        val bytes = MessageDigest.getInstance("SHA-256").digest(text.toByteArray())
        return bytes.joinToString("") { "%02x".format(it) }
    }

    // Empeche de fermer l'ecran de blocage avec le bouton retour
    override fun onBackPressed() {
        // Ne rien faire : on force a utiliser un des deux boutons proposes
    }
}
