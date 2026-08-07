# 🔥 Configuration Firebase / FCM

> **Important :** Firebase n'est **PAS** la base de données de l'app.
> La base de données est **Neon (PostgreSQL/PostGIS)** — voir `backend/.env` (`DATABASE_URL`).
> Firebase (FCM) sert **uniquement** aux notifications push (section 17 du cahier des charges).

## Les 2 fichiers de credentials

| Fichier | Où le placer | Rôle |
|---|---|---|
| Compte de service (`*-firebase-adminsdk-*.json`) | `backend/firebase-credentials.json` | **ENVOYER** les push (serveur) |
| `google-services.json` | `mobile/android/app/google-services.json` | **RECEVOIR** les push (Android) |

---

## Étape 1 — Créer le projet Firebase

1. https://console.firebase.google.com → **Créer un projet**
2. Nom : `sendwe-sos` (ou autre)
3. Google Analytics : **décocher** (inutile ici)

## Étape 2 — Compte de service (backend)

1. ⚙️ Paramètres du projet → **Comptes de service**
2. **Générer une nouvelle clé privée** → télécharge le JSON
3. Le placer dans le backend :
   ```
   Sendwe SOS backend/firebase-credentials.json
   ```
4. Activer dans `backend/.env` :
   ```env
   FCM_CREDENTIALS_JSON_PATH=C:/Users/Dell/Documents/Sendwe SOS backend/firebase-credentials.json
   FCM_ENABLED=true
   ```

## Étape 3 — `google-services.json` (Android)

1. Console Firebase → **Ajouter une app** → icône Android 🤖
2. Nom du package : **`com.sendwe.sendwe_sos`**
3. Télécharger `google-services.json` → le placer dans :
   ```
   Sendwe SOS mobile/android/app/google-services.json
   ```
4. Relancer le build : `flutter build apk --debug`

---

## ⚠️ Sécurité

- Ces fichiers JSON sont **secrets** — jamais commités (`.gitignore` déjà configuré).
- Le **compte de service** donne accès à l'envoi de notifications : ne le partagez jamais, ne le mettez pas dans le mobile.
- Le plugin Gradle Google Services est **optionnel** : le build compile sans Firebase, et FCM s'active automatiquement quand `google-services.json` est présent.

## ✅ Ce qui est déjà prêt dans le code

- **Backend** : canal FCM (`app/services/notifications.py`) — Noop si désactivé, FCM si `FCM_ENABLED=true`.
- **Mobile** : `lib/core/notification_service.dart` — init Firebase, permission, enregistrement du jeton via `PATCH /users/me {fcm_token}`.
- **Endpoint** : `PATCH /users/me` accepte `fcm_token` (stocké sur `users.fcm_token`, section 13.2).
- **Déclencheurs** : toutes les notifications de la section 17 (nouvelle demande, ambulance trouvée, en route, arrivée, terminée, annulation, échec).

## 🧪 Tester les push

- Besoin d'un **appareil/émulateur Android réel** (FCM ne marche pas sur simulateur iOS sans config).
- Vérifier la console Firebase → **Cloud Messaging** → logs de test.
