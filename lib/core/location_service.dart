/// Service de géolocalisation (section 18) avec buffer local (section 23).

import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'token_storage.dart';
import 'ws_client.dart';

class LocationService {
  Timer? _timer;
  bool _running = false;
  WSClient? _ws;

  /// Démarre l'envoi périodique GPS (10 s) tant que l'ambulancier est disponible.
  Future<void> start(WSClient ws) async {
    if (_running) return;
    _running = true;
    _ws = ws;
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _push());
  }

  Future<void> stop() async {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _push() async {
    final role = await TokenStorage.role();
    if (role != 'AMBULANCIER') return;

    final pos = await _currentPosition();
    if (pos == null) return;

    final payload = {
      'lat': pos.latitude,
      'lng': pos.longitude,
      'accuracy_m': pos.accuracy,
      'heading': pos.heading,
      'speed_kmh': pos.speed,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };

    // Canal WS en priorité ; buffer local des 5 dernières positions en secours (section 23)
    if (_ws != null) {
      try {
        _ws!.sendLocation(payload);
        return;
      } catch (_) {
        /* bascule sur REST */
      }
    }
    try {
      await apiClient.post('/locations', body: payload);
    } catch (_) {
      await _bufferLocation(payload);
    }
  }

  Future<Position?> _currentPosition() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _bufferLocation(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'gps_buffer';
    final list = prefs.getStringList(key) ?? [];
    list.add(jsonEncode(payload));
    if (list.length > 5) list.removeAt(0); // max 5 dernières positions
    await prefs.setStringList(key, list);
  }

  /// Envoie en rafale le buffer de positions à la reconnexion.
  Future<void> flushBuffer() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'gps_buffer';
    final list = prefs.getStringList(key) ?? [];
    if (list.isEmpty) return;
    await prefs.remove(key);
    for (final raw in list) {
      try {
        final payload = jsonDecode(raw) as Map<String, dynamic>;
        await apiClient.post('/locations', body: payload);
      } catch (_) {
        /* ignore */
      }
    }
  }
}
