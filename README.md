# Lafia Sna — application mobile (Flutter)

Application Android de l'Hôpital Virtuel, pour les patients et les infirmiers à domicile.
Elle utilise la même API Laravel que le site web ([Lafia-Sna-backend](https://github.com/HannaBaba2/Lafia-Sna-backend)).

## Tester sans rien installer (pour toute l'équipe)

Demandez le fichier **APK** à la développeuse, puis ouvrez-le sur un téléphone Android.
MIUI, Samsung… demandent d'autoriser l'installation depuis le gestionnaire de fichiers ou WhatsApp : acceptez.

- Tant que l'API n'est pas en ligne, l'APK fonctionne seulement sur **le même Wi-Fi** que l'ordinateur
  qui fait tourner le backend.
- Une fois l'API déployée sur Coolify (HTTPS), l'APK marche partout, en Wi-Fi comme en données mobiles.

## Installer le projet (développeurs)

### 1. Outils (une seule fois)

```bash
sudo snap install flutter --classic
flutter doctor
```

Aucun Android Studio n'est nécessaire. Selon ce que vous voulez lancer :

| Pour lancer sur… | À installer |
|---|---|
| **Chrome** | rien de plus |
| **Linux** (fenêtre sur l'ordinateur) | `sudo apt install clang cmake ninja-build g++ pkg-config libgtk-3-dev libsecret-1-dev libjsoncpp-dev` (sur Ubuntu 22.04, ajouter `libstdc++-12-dev`) |
| **Un téléphone Android** en USB | le SDK Android en ligne de commande, voir [plus bas](#sdk-android-sans-android-studio) |

### 2. Lancer le backend

Installez d'abord le backend en local en suivant la partie « Démarrer sans Docker » du README du dépôt
backend (PHP 8.3, Composer, PostgreSQL, `php artisan migrate --seed` pour les hôpitaux de démonstration).
Puis, à chaque fois :

```bash
cd ../Lafia-Sna-backend
php artisan serve --host=0.0.0.0 --port=8000
curl http://localhost:8000/api/hospitals      # dans un autre terminal : doit afficher du JSON
```

`--host=0.0.0.0` est indispensable pour tester sur un téléphone : sans lui, seul l'ordinateur peut joindre l'API.
Si le port 8000 est déjà pris, utilisez un autre port (`--port=8001`) et reportez-le dans l'étape 3.

Avec Docker, c'est possible aussi : `APP_PORT=8001 SEED_DEMO=true docker compose up --build -d`.

### 3. Dire à l'appli où est l'API

Le fichier n'est jamais commité (il dépend de chaque machine) :

```bash
cp dart_defines.example.json dart_defines.local.json
```

| Vous lancez sur… | `API_URL` dans le fichier |
|---|---|
| Chrome ou Linux | `http://localhost:8000/api` (déjà la valeur de l'exemple) |
| Un vrai téléphone (même Wi-Fi) | `http://<IP du PC>:8000/api` — l'IP s'obtient avec `hostname -I` |
| L'API en ligne | `https://<domaine-api>/api` |

`WEB_URL` (facultatif) est l'adresse du site web : l'appli l'ouvre pour les comptes hôpital et l'équipe,
dont l'espace de gestion est sur le site. Laissez-le vide pour ne pas afficher de lien.

**Chrome et téléphone** : l'adresse de l'appli doit être autorisée par le backend (CORS).
Dans le `.env` du backend, ajoutez-la à `FRONTEND_URL`, séparée par des virgules :

```bash
# Exemple : FRONTEND_URL=http://localhost:5173,http://localhost:5174,http://192.168.1.20:5174
php artisan config:clear      # au cas où la configuration aurait été mise en cache
```

L'appli Android et Linux n'est pas concernée par le CORS : seul Chrome l'est.
(Avec Docker : `docker compose up -d --force-recreate app` pour relire le `.env`.)

### 4. Lancer l'appli

```bash
flutter pub get

# Linux
flutter run -d linux --dart-define-from-file=dart_defines.local.json

# Chrome (port fixe, pour le CORS)
flutter run -d chrome --web-port=5174 --dart-define-from-file=dart_defines.local.json

# Téléphone branché en USB (débogage USB activé)
flutter run --dart-define-from-file=dart_defines.local.json
```

`r` recharge en une seconde après une modification, `R` redémarre l'appli, `q` quitte.
Après un changement de `pubspec.yaml`, des polices ou du manifeste Android, il faut quitter et relancer.

**Comptes de test** : créez un compte patient depuis l'appli. Pour un compte infirmier, inscrivez-vous comme
infirmier sur le site web, puis validez-le depuis l'espace Lafia Sna.

## Fabriquer l'APK à partager

```bash
# Test sur le même Wi-Fi que le backend
flutter build apk --debug --target-platform android-arm64 --dart-define=API_URL=http://<IP du PC>:8000/api

# Avec l'API en ligne
flutter build apk --release --dart-define=API_URL=https://<domaine-api>/api
```

Le fichier est dans `build/app/outputs/flutter-apk/`. Envoyez-le par WhatsApp, Drive ou câble USB.
Une version `--release` refuse les API en `http://` : il faut l'API en HTTPS.

## SDK Android sans Android Studio

Utile si le disque est petit : on peut tout mettre sur un autre disque (ici `/data`).

```bash
mkdir -p /data/android/cmdline-tools /data/gradle && cd /data/android/cmdline-tools
# Dernière version : https://developer.android.com/studio#command-line-tools-only
curl -LO https://dl.google.com/android/repository/commandlinetools-linux-<version>_latest.zip
unzip commandlinetools-linux-*_latest.zip && mv cmdline-tools latest

cat >> ~/.bashrc <<'EOF'
export ANDROID_HOME=/data/android
export ANDROID_SDK_ROOT=/data/android
export GRADLE_USER_HOME=/data/gradle
export PATH="$PATH:/data/android/cmdline-tools/latest/bin:/data/android/platform-tools"
EOF
source ~/.bashrc

yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0"
flutter config --android-sdk /data/android
```

La première construction télécharge encore le NDK et Gradle (1 à 2 Go). Si la connexion coupe,
relancez simplement la commande : ce qui est déjà téléchargé est gardé.

Sur le téléphone : **Options pour les développeurs → Débogage USB** (sur Xiaomi : appuyer 7 fois sur
« Version MIUI », puis activer aussi « Installer via USB »).

## Ce qui est déjà configuré

- `android/app/src/main/AndroidManifest.xml` : Internet, position approximative, ouverture du composeur,
  des cartes et des e-mails (Android 11+), `allowBackup="false"` pour le jeton de connexion.
- `android/app/src/debug/AndroidManifest.xml` : API en `http://` autorisée **en développement seulement**.
- Police Figtree et logo intégrés à l'appli (`assets/`) : rien à télécharger à l'ouverture.

## Tests

```bash
flutter analyze
flutter test
```

## Organisation du code

```
lib/
  api/        appels à l'API (client HTTP, modèles)
  auth/       connexion, inscription, mot de passe, session
  screens/    un fichier par écran (hôpitaux, service, chat, infirmiers, alertes…)
  widgets/    éléments réutilisés (pastilles, formulaires, feuilles du bas)
  format.dart, location.dart, theme.dart
```
