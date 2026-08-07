/// Notifications push (FCM) — section 17.
///
/// IMPORTANT : Firebase N'EST PAS la base de données de l'app.
/// La base de données est Neon (PostgreSQL/PostGIS) — voir .env DATABASE_URL.
/// Firebase (FCM) est utilisé UNIQUEMENT pour recevoir les notifications push
/// sur le téléphone (nouvelle intervention, ambulance trouvée, etc.).
/// Aucune donnée métier n'est stockée dans Firebase.
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'api_client.dart';
import 'token_storage.dart';

/// Affiche une notification reçue quand l'app est au premier plan.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Le handler d'arrière-plan doit initialiser Firebase si l'app est tuée.
  await Firebase.initializeApp();
}

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  bool _initialized = false;
  FirebaseMessaging? _messaging;

  Future<void> init() async {
    if (_initialized) return;
    await Firebase.initializeApp();
    _messaging = FirebaseMessaging.instance;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Demande la permission de notification
    final settings = await _messaging!.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _registerToken();
    }

    _initialized = true;
  }

  /// Envoie le jeton FCM au backend (stocké sur users.fcm_token, section 13.2).
  /// Le backend l'utilise pour cibler les push (section 17).
  Future<void> _registerToken() async {
    final token = await _messaging!.getToken();
    if (token == null) return;
    final access = await TokenStorage.accessToken();
    if (access == null) return;
    try {
      // Endpoint de mise à jour du jeton (PATCH /users/me + fcm_token)
      await apiClient.patch('/users/me', body: {'fcm_token': token});
    } catch (_) {
      // Le jeton sera réenregistré à la prochaine connexion
    }
  }

  /// Abonnement aux notifications entrantes.
  void onMessage({required void Function(Map<String, dynamic> data) handler}) {
    FirebaseMessaging.onMessage.listen((message) {
      final data = Map<String, dynamic>.from(message.data);
      handler(data);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final data = Map<String, dynamic>.from(message.data);
      handler(data);
    });
  }

  /// Décodage pratique des données d'une notification FCM.
  static Map<String, dynamic> decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return {};
    try {
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
