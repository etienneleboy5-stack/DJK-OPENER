# DJK Opener

Application de controle parental qui bride l'acces aux reseaux sociaux
installes sur un telephone Android, pour aider les eleves/etudiants a
se concentrer sur leurs etudes.

Developpe par **DJK Etienne**.

## Comment ca marche

1. A la premiere ouverture, l'app demande de **definir un code parent**
   (4 a 6 chiffres). C'est le seul moyen de debloquer les apps par la
   suite.
2. Le tableau de bord liste automatiquement les reseaux sociaux
   installes sur le telephone (Facebook, Instagram, WhatsApp, TikTok,
   Snapchat, YouTube, X, Discord, etc.) avec un interrupteur pour
   chacun.
3. Le parent doit **activer le service d'accessibilite** (bouton
   "Activer" affiche tant que ce n'est pas fait) : c'est ce qui permet
   a l'app de detecter quand une application bloquee est ouverte.
4. Des qu'une app bloquee est lancee, un ecran natif "DJK Opener"
   s'affiche par-dessus avec un message clair : *"[App] a ete bride
   par DJK Opener. Merci d'attendre qu'un parent vous autorise
   l'acces."* L'eleve peut revenir a l'accueil, ou saisir le code
   parent pour ouvrir directement le tableau de bord et lever le
   blocage si le parent est present.

## Points importants (a lire avant publication)

### Permission d'accessibilite : declaration Google Play obligatoire
Google est strict sur l'usage de l'API Accessibilite en dehors de
l'accessibilite au sens propre. Les apps de controle parental sont
autorisees a l'utiliser, **mais il faut le declarer explicitement**
dans la Play Console (Formulaire de declaration d'usage de
l'accessibilite, categorie "controle parental") avant publication,
sous peine de rejet/suspension. Voir la doc officielle Play Console
> Policy > Permissions Accessibilite.

### La desinstallation arrete le blocage -- c'est voulu
Contrairement a ce qu'on pourrait vouloir pour un controle "total",
cette version n'essaie pas de survivre a la desinstallation. C'est un
choix assume : les mecanismes qui empechent la desinstallation ou qui
se reinstallent seuls sont associes aux logiciels espions/stalkerware
et sont interdits par Google Play et par la loi dans de nombreux pays,
meme presentes comme du controle parental. Si tu veux renforcer la
protection contre une desinstallation impulsive par l'enfant (pas
contre l'enfant en general), l'option legitime est l'API **Device
Admin**, qui demande une confirmation avant desinstallation -- je peux
l'ajouter si tu veux dans une prochaine version.

### Le code parent n'est pas recuperable
Il n'y a pas d'ecran "code oublie" pour l'instant : si le parent perd
son code, il faut desinstaller/reinstaller l'app (ce qui leve le
blocage). A voir si tu veux un systeme de recuperation par e-mail plus
tard (ca demande un backend).

## Compiler l'APK via GitHub Actions (aucune install locale requise)

1. Cree un nouveau depot GitHub.
2. Mets tout le contenu de ce dossier a la racine du depot, en gardant
   l'arborescence (important : `.github/workflows/build.yml`,
   `android/`, `lib/`, `pubspec.yaml`).
3. Commit + push sur la branche `main`.
4. Onglet **Actions** du depot -> le workflow "Build APK" se lance
   automatiquement (~8-12 minutes).
5. Une fois vert, clique sur le run -> section **Artifacts** en bas de
   page -> telecharge `djk-opener-apk.zip`.
6. Dezippe -> tu obtiens `app-release.apk`. Transfere-le sur le
   telephone et installe-le (autoriser "sources inconnues").

## Activer le service apres installation

Apres avoir installe l'APK, l'activation du blocage necessite une
etape manuelle (protection normale d'Android, on ne peut pas
l'automatiser) :

1. Ouvre DJK Opener, configure le code parent.
2. Appuie sur "Activer" dans la carte de statut.
3. Android t'envoie vers **Parametres > Accessibilite** -> cherche
   "DJK Opener" dans la liste -> active-le -> confirme le message
   d'avertissement systeme (normal, Android affiche toujours ce
   message pour les services d'accessibilite).
4. Reviens dans l'app : la carte de statut passe au vert.

## Structure du projet

```
lib/main.dart                     Interface Flutter (configuration + tableau de bord)
android/app/src/main/kotlin/com/djk/opener/
  MainActivity.kt                 Pont Flutter <-> Android (PIN, liste d'apps, etc.)
  MonitorAccessibilityService.kt  Detecte l'ouverture des apps bloquees
  BlockActivity.kt                Ecran de blocage natif affiche par-dessus
  SecureStore.kt                  Stockage du code PIN (hash) et de la liste bloquee
android/app/src/main/res/
  layout/activity_block.xml       Mise en page de l'ecran de blocage
  xml/accessibility_service_config.xml
  mipmap-*/ic_launcher.png        Logo de l'application
.github/workflows/build.yml       Compilation automatique sur GitHub
```

## Pour aller plus loin (pistes si tu veux une v2)

- Plages horaires (bloque seulement le soir/en semaine, libre le
  week-end).
- Ecran "changer le code" accessible uniquement apres verification du
  code actuel (deja present dans le tableau de bord).
- Protection Device Admin contre la desinstallation impulsive.
- Statistiques de temps passe avant blocage (necessite
  `UsageStatsManager`, permission supplementaire).

Dis-moi si tu veux que j'ajoute une de ces fonctionnalites.
