# Tableau de bord — appli iPad mini 4 (iPadOS 15)

Même interface que la version Android (le `index.html` de ce dépôt, copié de `dash-mini-4`), dans une appli iOS (WKWebView) qui fournit le pont `window.Native` : réseau (Airzone en HTTP local, météo, GitHub, Tuya), réglages, batterie, veille, Bluetooth (lumière LED).

**État : appli 0.2 — compile sur GitHub Actions (Xcode 26, cible iPadOS 15.0). Pas encore essayée sur un vrai iPad.**
Faits : étapes 1 (coque), 2 (HTTP + réglages), 3 (Bluetooth), import automatique des réglages. étape 4 refaite sans signature. Pas fait : étape 5 (signature automatisée, mise en place sur l'iPad).

## Récupérer l'appli
1. GitHub > dépôt `Dashboard-Ipad` > onglet **Actions** > dernier passage de « iPad (IPA non signé) » (branche `main`).
2. En bas de la page, section **Artifacts** : télécharger `TableauDeBord-iPad-unsigned-ipa` (zip contenant `TableauDeBord-iPad-unsigned.ipa`).

L'IPA n'est **pas signé** : il faut le signer avec ton identifiant Apple au moment de l'installer.

## Installer sur l'iPad (depuis ton PC Windows)
- Outil : **Sideloadly** (ou AltStore). Installer d'abord iTunes et iCloud depuis le site d'Apple (pas le Microsoft Store).
- Brancher l'iPad en USB, déverrouillé, « Faire confiance » à l'ordinateur.
- Glisser l'IPA dans Sideloadly, saisir l'identifiant Apple, Start.
- Sur l'iPad : Réglages > Général > Gestion des appareils (VPN et gestion de l'appareil) > ton identifiant > **Faire confiance**. (Pas de « Mode développeur » à activer sur iPadOS 15 : il n'existe que depuis iPadOS 16.)
- Compte Apple **gratuit** : l'appli expire au bout de **7 jours** (il faut la ré-installer ou la rafraîchir, 3 applis maximum). Compte développeur payant : 1 an.
- Conseil : utiliser un identifiant Apple dédié à ça.

## Premier lancement
- Accepter **Bluetooth** et **Réseau local** (sans « Réseau local », la clim Airzone reste injoignable).
- Autre > Réglages : adresse Airzone (`ip:port`), latitude/longitude, jeton de diagnostic, etc. — comme sur Android.
- Lumière LED : sur iOS il n'y a pas d'adresse MAC. Laisser le champ **vide** (ou garder l'ancienne adresse) : l'appli cherche un appareil nommé BLEDOM / ELK / LEDBLE, ou exposant le service FFF0, et mémorise son identifiant. Si plusieurs lumières voisines posent problème : saisir un bout du nom, ou l'identifiant iOS.
- Réglages automatiques : voir « Import automatique des réglages » ci-dessous.

## Import automatique des réglages
- L'appli crée dans son dossier (app Fichiers > Sur mon iPad > Tableau de bord, ou « Partage de fichiers » d'iTunes / de l'app Appareils Apple sur Windows) un modèle `exemple-reglages.txt` : une ligne `clé=valeur` par réglage (`updurl`, `diagrepo`, `diagtok`, `airzone`, `system`, `zone`, `lat`, `lon`, `ical`, `lum`, `lum2`, `tyname`, `tyregion`, `tyid`, `tysecret`, `tydevice`, `tycode`).
- Copier ce modèle sous le nom **`reglages.txt`**, le remplir, le déposer dans le même dossier.
- L'appli le lit **toute seule** à chaque lancement et quand elle revient au premier plan, mais seulement si son contenu a changé. Elle fusionne les valeurs dans les réglages et affiche quelques secondes « Réglages importés (n modifiés) » (la page se recharge si elle était déjà ouverte).
- Une valeur **vide** ne remplace rien ; une clé inconnue est ignorée et signalée dans le message.
- Les anciens `ical.txt` (lien iCal) et `tuya.txt` (id, secret, device, region, code, name) sont lus aussi ; `reglages.txt` l'emporte en cas de doublon. Le bouton « Importer » de la page marche toujours.
- Le fichier reste sur l'iPad, avec tes clés dedans : ne le laisse pas ailleurs que dans ce dossier, et ne le mets jamais sur GitHub.

## Mises à jour de l'interface (sans signature)
- **Adresse à saisir** dans Autre > Réglages > « Adresse des mises à jour » (ou `updurl=` dans `reglages.txt`) : `https://raw.githubusercontent.com/ClementLGS/Dashboard-Ipad/main`
- **Deux versions** : la branche `main` (version normale, sans barre de FPS ni bouton « Simuler une erreur ») et la branche `test` (avec la barre de FPS et « Simuler une erreur », nom d'interface terminé par TEST). Adresse `main` : `https://raw.githubusercontent.com/ClementLGS/Dashboard-Ipad/main`. Adresse `test` : `https://raw.githubusercontent.com/ClementLGS/Dashboard-Ipad/test`. Changer d'adresse dans Réglages suffit pour passer de l'une à l'autre (puis « Mettre à jour »). Chaque branche a son propre `version.json`.
- **Nom des versions** : `main` s'appelle « 3.X iPad » et `test` « 3.X iPad (beta) », avec le même X sur les deux (3.16, puis 3.17…). X augmente de 1 à chaque nouvelle version publiée. Le numéro interne (`UI_CODE`/`TDBV`) vaut 3.X × 100 + 0, donc 3160 pour 3.16, et il ne se réutilise jamais.
- **Le dépôt doit être public** pour que l'iPad lise cette adresse (un dépôt privé renvoie une erreur 404 sans jeton). Il ne contient aucun secret.
- L'iPad vérifie 30 s après le lancement, puis toutes les 6 h (ou à la main avec « Mettre à jour »). Si le numéro d'interface de `version.json` diffère de celui affiché, il télécharge `index.html` et l'enregistre, puis recharge la page. « Version précédente » revient à la version d'avant.
- **Aucune signature** : l'appli enregistre toute interface qui ressemble à une interface valide (contient `window.LOCAL`, marqueurs `TDBV`/`TDBA`, `TDBA` pas plus haut que le niveau du pont iPad). L'empreinte `uisha` de `version.json` ne sert qu'à écarter un fichier abîmé. Conséquence : quiconque contrôle l'adresse de mise à jour (ou le dépôt) peut changer l'interface, qui a accès à la clim, aux lumières et aux clés Tuya. Le code de vérification de signature de la version précédente est dans l'historique de `dash-mini-4` (commit `2e6a978`).
- **Publier une nouvelle interface** : modifier `index.html` (nouveau numéro : `UI_CODE`, `UI_NAME` et `<!--TDBV:… -->` identiques), lancer `python3 tools/version.py`, pousser `index.html` et `version.json`. Un numéro déjà utilisé ne se réutilise jamais.
- L'interface mise à jour remplace celle livrée dans l'IPA. Si tu installes un nouvel IPA dont l'interface livrée est différente, la mise à jour précédente est écartée et la page se remet à jour toute seule ensuite.
- Une interface qui exige un pont plus récent que l'iPad (`TDBA` > 211) est refusée avec un message : il faut alors recompiler et réinstaller l'appli.
- Pas d'installation d'appli (APK) sur iPad : la nouvelle version de l'appli elle-même (Swift) passe par un nouvel IPA.

## Différences avec Android
- Pas d'économie d'énergie automatique ni de mode « Accès guidé » depuis l'appli : iOS ne le permet pas (Accès guidé : triple clic sur le bouton principal, à faire à la main). La veille met la luminosité au minimum et l'écran reste allumé.
- Pas d'installation d'APK. Une nouvelle version de l'appli elle-même (Swift) passe par un nouvel IPA : relancer le workflow (Actions > Run workflow) et ré-installer.
- Open-Meteo est d'abord essayé en HTTP (astuce Android 4.4) : iOS le refuse, la page retombe aussitôt sur HTTPS. Sans conséquence.

## Compiler
Rien à faire à la main : le workflow `.github/workflows/ios.yml` copie `index.html`, génère le projet avec XcodeGen (`ios/project.yml`), compile sans signature et publie l'IPA.

## Apple Music (branche `test` seulement, version 3.20)
- La tuile musique commande l'appli **Musique** de l'iPad (lecture/pause, suivant, précédent, titre et pochette en cours) et lance tes playlists (Autre > Musique). Elle remplace Spotify dans cette branche.
- Elle passe par le lecteur système d'Apple : aucun compte développeur payant. Il faut l'abonnement Apple Music pour lire le catalogue, et une playlist doit être dans ta bibliothèque.
- Au premier lancement, l'iPad demande l'autorisation « Médias et Apple Music » : accepte. Refusée par erreur : Réglages iPad > Tableau de bord > Médias et Apple Music.
- Cette interface exige le pont 212 : elle ne se met à jour que sur un IPA compilé depuis `test` (sinon l'appli la refuse et demande de réinstaller).
