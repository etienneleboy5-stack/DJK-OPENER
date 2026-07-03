// DJK Opener
// -----------------------------------------------------------------
// Application de controle parental : bride l'acces aux reseaux sociaux
// installes sur le telephone. Le deverrouillage se fait uniquement via
// un code PIN defini par le parent a la premiere configuration.
//
// Developpe par DJK Etienne.
// -----------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const MethodChannel _native = MethodChannel('djk_opener/native');

const Color kBleu = Color(0xFF2A5CD9);
const Color kFond = Color(0xFF0B1220);
const Color kCarte = Color(0xFF16213A);
const Color kTexte = Color(0xFFEFF3FB);
const Color kTexteAtt = Color(0xFF8C97AC);
const Color kVert = Color(0xFF3DD9A0);

void main() {
  runApp(const DjkOpenerApp());
}

class DjkOpenerApp extends StatelessWidget {
  const DjkOpenerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DJK Opener',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kFond,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kBleu,
          brightness: Brightness.dark,
        ),
      ),
      home: const StartupGate(),
    );
  }
}

/// Decide au demarrage si on affiche la configuration du PIN
/// (premiere installation) ou directement le tableau de bord.
class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  bool? _pinDejaConfigure;

  @override
  void initState() {
    super.initState();
    _verifier();
  }

  Future<void> _verifier() async {
    bool configure = false;
    try {
      configure = await _native.invokeMethod('isPinSet') as bool;
    } catch (_) {}
    setState(() => _pinDejaConfigure = configure);
  }

  @override
  Widget build(BuildContext context) {
    if (_pinDejaConfigure == null) {
      return const Scaffold(
        backgroundColor: kFond,
        body: Center(child: CircularProgressIndicator(color: kBleu)),
      );
    }
    return _pinDejaConfigure! ? const DashboardPage() : const PinSetupPage();
  }
}

// ===================================================================
// Ecran de configuration initiale du code parent
// ===================================================================
class PinSetupPage extends StatefulWidget {
  const PinSetupPage({super.key});

  @override
  State<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage> {
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _erreur;
  bool _enCours = false;

  Future<void> _valider() async {
    final pin = _pinCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (pin.length < 4 || pin.length > 6 || int.tryParse(pin) == null) {
      setState(() => _erreur = "Le code doit contenir 4 a 6 chiffres.");
      return;
    }
    if (pin != confirm) {
      setState(() => _erreur = "Les deux codes ne correspondent pas.");
      return;
    }

    setState(() {
      _enCours = true;
      _erreur = null;
    });

    try {
      await _native.invokeMethod('setPin', {'pin': pin});
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } catch (e) {
      setState(() {
        _erreur = "Erreur lors de l'enregistrement du code.";
        _enCours = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFond,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const _Logo(size: 84),
              const SizedBox(height: 20),
              const Text(
                "Bienvenue sur DJK Opener",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: kTexte,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Definissez un code parent. Il sera le seul moyen de "
                "debloquer les reseaux sociaux brides sur ce telephone.",
                textAlign: TextAlign.center,
                style: TextStyle(color: kTexteAtt, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 36),
              _ChampPin(controller: _pinCtrl, label: "Code parent (4 a 6 chiffres)"),
              const SizedBox(height: 16),
              _ChampPin(controller: _confirmCtrl, label: "Confirmer le code"),
              if (_erreur != null) ...[
                const SizedBox(height: 14),
                Text(_erreur!,
                    style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13)),
              ],
              const SizedBox(height: 28),
              _BoutonPrincipal(
                texte: "Valider et continuer",
                enCours: _enCours,
                onPressed: _valider,
              ),
              const Spacer(),
              const _SignatureFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChampPin extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const _ChampPin({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 6,
      textAlign: TextAlign.center,
      style: const TextStyle(color: kTexte, fontSize: 20, letterSpacing: 6),
      decoration: InputDecoration(
        counterText: "",
        labelText: label,
        labelStyle: const TextStyle(color: kTexteAtt),
        filled: true,
        fillColor: kCarte,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ===================================================================
// Tableau de bord principal
// ===================================================================
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _accessibiliteActive = false;
  List<Map<String, dynamic>> _apps = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    bool actif = false;
    List<Map<String, dynamic>> apps = [];
    try {
      actif = await _native.invokeMethod('isAccessibilityEnabled') as bool;
      final raw = await _native.invokeMethod('getKnownApps') as List<dynamic>;
      apps = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {}
    setState(() {
      _accessibiliteActive = actif;
      _apps = apps;
      _chargement = false;
    });
  }

  Future<void> _ouvrirReglagesAccessibilite() async {
    try {
      await _native.invokeMethod('openAccessibilitySettings');
    } catch (_) {}
  }

  Future<void> _toggleApp(String package, bool bloque) async {
    setState(() {
      final i = _apps.indexWhere((a) => a['package'] == package);
      if (i != -1) _apps[i]['blocked'] = bloque;
    });
    try {
      await _native.invokeMethod(
        'setAppBlocked',
        {'package': package, 'blocked': bloque},
      );
    } catch (_) {}
  }

  Future<bool> _demanderPin(String titre) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCarte,
        title: Text(titre, style: const TextStyle(color: kTexte)),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(color: kTexte, letterSpacing: 4),
          decoration: const InputDecoration(counterText: ""),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          FilledButton(
            onPressed: () async {
              final valide = await _native.invokeMethod(
                'verifyPin',
                {'pin': ctrl.text.trim()},
              ) as bool;
              if (context.mounted) Navigator.pop(ctx, valide);
            },
            child: const Text("Valider"),
          ),
        ],
      ),
    );
    if (ok == false) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Code incorrect.")),
        );
      }
    }
    return ok ?? false;
  }

  Future<void> _changerPin() async {
    final autorise = await _demanderPin("Code parent actuel");
    if (!autorise) return;
    if (!mounted) return;
    final nouveau = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          backgroundColor: kCarte,
          title: const Text("Nouveau code", style: TextStyle(color: kTexte)),
          content: TextField(
            controller: ctrl,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: const TextStyle(color: kTexte, letterSpacing: 4),
            decoration: const InputDecoration(counterText: ""),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annuler"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text("Enregistrer"),
            ),
          ],
        );
      },
    );
    if (nouveau != null && nouveau.length >= 4 && nouveau.length <= 6) {
      await _native.invokeMethod('setPin', {'pin': nouveau});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Code parent mis a jour.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFond,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _charger,
          color: kBleu,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: const [
                  _Logo(size: 44),
                  SizedBox(width: 12),
                  Text(
                    "DJK Opener",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: kTexte,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _CarteStatut(
                actif: _accessibiliteActive,
                onActiver: _ouvrirReglagesAccessibilite,
              ),
              const SizedBox(height: 24),
              const Text(
                "Reseaux sociaux detectes",
                style: TextStyle(
                  color: kTexte,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              if (_chargement)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: kBleu)),
                )
              else if (_apps.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    "Aucun reseau social courant detecte sur ce telephone.",
                    style: TextStyle(color: kTexteAtt),
                  ),
                )
              else
                ..._apps.map((app) => _CarteApp(
                      nom: app['name'] as String,
                      bloque: app['blocked'] as bool,
                      onChanged: (v) => _toggleApp(app['package'] as String, v),
                    )),
              const SizedBox(height: 24),
              _CarteAction(
                icone: Icons.lock_outline,
                titre: "Modifier le code parent",
                onTap: _changerPin,
              ),
              const SizedBox(height: 32),
              const _SignatureFooter(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarteStatut extends StatelessWidget {
  final bool actif;
  final VoidCallback onActiver;
  const _CarteStatut({required this.actif, required this.onActiver});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCarte,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: actif ? kVert.withOpacity(0.4) : Colors.orange.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            actif ? Icons.shield : Icons.warning_amber_rounded,
            color: actif ? kVert : Colors.orange,
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actif ? "Protection active" : "Configuration requise",
                  style: const TextStyle(
                    color: kTexte,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  actif
                      ? "Le blocage des reseaux fonctionne correctement."
                      : "Active le service d'accessibilite pour que le "
                          "blocage fonctionne.",
                  style: const TextStyle(color: kTexteAtt, fontSize: 12.5),
                ),
              ],
            ),
          ),
          if (!actif)
            TextButton(
              onPressed: onActiver,
              child: const Text("Activer"),
            ),
        ],
      ),
    );
  }
}

class _CarteApp extends StatelessWidget {
  final String nom;
  final bool bloque;
  final ValueChanged<bool> onChanged;
  const _CarteApp({
    required this.nom,
    required this.bloque,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: kCarte,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(nom, style: const TextStyle(color: kTexte, fontSize: 15)),
          ),
          Switch(
            value: bloque,
            activeColor: kBleu,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _CarteAction extends StatelessWidget {
  final IconData icone;
  final String titre;
  final VoidCallback onTap;
  const _CarteAction({
    required this.icone,
    required this.titre,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kCarte,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icone, color: kTexteAtt, size: 20),
              const SizedBox(width: 14),
              Text(titre, style: const TextStyle(color: kTexte, fontSize: 15)),
              const Spacer(),
              const Icon(Icons.chevron_right, color: kTexteAtt),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoutonPrincipal extends StatelessWidget {
  final String texte;
  final bool enCours;
  final VoidCallback onPressed;
  const _BoutonPrincipal({
    required this.texte,
    required this.enCours,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: enCours ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kBleu,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: enCours
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : Text(texte,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final double size;
  const _Logo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: kBleu,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.shield_moon_rounded, color: Colors.white, size: size * 0.55),
    );
  }
}

class _SignatureFooter extends StatelessWidget {
  const _SignatureFooter();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        children: [
          Text(
            "Developpe par DJK Etienne",
            style: TextStyle(
              color: kTexteAtt,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2),
          Text(
            "DJK Opener v1.0",
            style: TextStyle(color: Color(0xFF556077), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
