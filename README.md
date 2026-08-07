# 🚑 Sendwe SOS — Application Mobile (Flutter)

Application mobile pour **patients** (demande d'ambulance avec GPS) et **ambulanciers** (acceptation/refus des courses), développée en **Flutter**.

## Prérequis

- Flutter SDK ≥ 3.x (`C:\flutter\bin\flutter.bat` sous Windows)
- Android Studio (SDK Android)
- Backend FastAPI démarré (port 8000)

## Configuration

L'URL du backend est définie dans `lib/core/api_client.dart` (variable `baseUrl`). Par défaut :

- Émulateur Android : `http://10.0.2.2:8000`
- Appareil physique : l'IP LAN de votre machine (ex. `http://192.168.1.10:8000`)

## Lancer l'application

```bash
flutter pub get
flutter run
```

## Build APK

```bash
flutter build apk --debug      # APK debug rapide
flutter build apk --release    # APK de production (signé)
```

> **Note** : le plugin Google Services (Firebase) est **optionnel** dans `android/app/build.gradle.kts`.
> Le build fonctionne sans `google-services.json`. Il ne s'active que lorsque le fichier est présent.

## 🔥 Firebase / FCM (Notifications Push)

Firebase n'est utilisé que pour les **notifications push** (FCM) — ce n'est PAS une base de données.
La base de données reste **Neon (PostgreSQL/PostGIS)** côté backend.

### 1) Créer le projet Firebase

1. Aller sur [console.firebase.google.com](https://console.firebase.google.com) → **Ajouter un projet**.
2. Nom : `sendwe-sos` → **Continuer**.
3. Google Analytics : **désactivé** (pas nécessaire) → **Créer le projet**.

### 2) Partie ANDROID (application mobile) — fichier `google-services.json`

1. Dans la console Firebase → **icône Android** (« + » / « Ajouter une app »).
2. Nom du package : `com.sendwe.sendwe_sos` (obligatoire, identique au projet).
3. Cliquer **Enregistrer l'application** → Firebase génère `google-services.json`.
4. **Télécharger** ce fichier et le placer ici :
   ```
   android/app/google-services.json
   ```
5. Le plugin Google Services est déjà configuré dans le Gradle — il s'activera automatiquement.

### 3) Partie BACKEND (serveur FastAPI) — fichier `firebase-credentials.json`

1. Dans la console Firebase → **⚙️ Paramètres du projet** → onglet **Comptes de service**.
2. Bouton **Générer une nouvelle clé privée** → télécharge `sendwe-sos-firebase-adminsdk-xxxx.json`.
3. Renommer et placer ce fichier ici :
   ```
   ..\Sendwe SOS backend\firebase-credentials.json
   ```
4. Dans le backend, éditer `.env` :
   ```env
   FCM_ENABLED=true
   FCM_CREDENTIALS_JSON_PATH=firebase-credentials.json
   ```

### 4) Activer les notifications

Une fois les 2 fichiers en place, reconstruire l'app et relancer le backend. L'envoi des push FCM est géré côté backend (`app/services/notifications.py`), avec repli sur l'affichage local si FCM est désactivé.

> **⚠️ Sécurité** : `google-services.json` et `firebase-credentials.json` sont ignorés par Git (voir `.gitignore`).
> Ne jamais les committer publiquement.

## Structure du projet

```
lib/
  core/       → api_client, ws_client, location_service (GPS), token_storage, theme, notification_service
  features/
    auth/     → login, register
    home/     → role_router (patient / ambulancier)
    patient/  → demander une ambulance (P1-P8)
    driver/   → courses assignées (D1-D5)
    history/  → historique des trajets
    profile/  → profil utilisateur
    settings/ → réglages
  shared/     → widgets, sos_map
```
