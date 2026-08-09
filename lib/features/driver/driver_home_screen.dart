/// D1 — Accueil ambulancier : bascule disponibilité + intervention active (section 9.C).

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/api_client.dart';
import '../../core/location_service.dart';
import '../../core/theme.dart';
import '../../core/ws_client.dart';
import 'driver_history_screen.dart';
import 'driver_profile_screen.dart';
import 'incoming_request_screen.dart';
import 'active_trip_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool? _isAvailable;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _activeTrip;
  bool _loading = true;
  String? _error;
  WSClient? _ws;
  final _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _load();
    _ws = WSClient(
      // Resynchronisation REST à la reconnexion (section 16.1)
      onReconnect: _load,
      handlers: {
        'emergency.assigned': (data) => _openIncoming(data),
        'emergency.cancelled': (_) => _load(),
        'emergency.status.updated': (_) => _load(),
      },
    );
    _ws!.connect();
  }

  Future<void> _load() async {
    try {
      final data = await apiClient.get('/drivers/me') as Map<String, dynamic>;
      final ambulance = data['ambulance'] as Map<String, dynamic>?;
      setState(() {
        _profile = data;
        _activeTrip = data['active_trip'] as Map<String, dynamic>?;
        _isAvailable = data['is_available'] as bool;
        if (ambulance == null)
          _error =
              'Aucune ambulance ne vous est assignée, contactez votre hôpital';
      });
    } catch (e) {
      setState(
        () => _error = e is ApiException ? e.message : 'Erreur de chargement',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openIncoming(Map<String, dynamic> data) {
    final tripId = data['trip_id'] as String?;
    if (tripId == null) return;
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => IncomingRequestScreen(tripId: tripId)),
    );
  }
  Future<void> _toggleAvailability(bool value) async {
    setState(() => _error = null);

    // GPS requis pour passer disponible (section 18)
    if (value) {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(
          () => _error = 'Activez votre localisation pour être disponible',
        );
        return;
      }
    }

    try {
      await apiClient.patch(
        '/drivers/me/availability',
        body: {'is_available': value},
      );
      setState(() => _isAvailable = value);
      if (value) {
        await _locationService.start(_ws!);
      } else {
        await _locationService.stop();
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Connexion impossible, vérifiez votre réseau');
    }
  }

  @override
  void dispose() {
    _locationService.stop();
    _ws?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final ambulance = _profile?['ambulance'] as Map<String, dynamic>?;
    final hasActiveTrip = _activeTrip != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historique',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DriverHistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Mon profil',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DriverProfileScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Bandeau intervention active (D1) -> ouvre D3
          if (hasActiveTrip) ...[
            Card(
              color: AppColors.active.withValues(alpha: 0.1),
              child: ListTile(
                leading: const Icon(
                  Icons.emergency,
                  color: AppColors.active,
                ),
                title: const Text('Intervention en cours'),
                subtitle: Text(
                  ((_activeTrip!['status'] as String?) ?? 'En cours')
                      .replaceAll('_', ' '),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ActiveTripScreen(
                      tripId: _activeTrip!['id'] as String,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            child: SwitchListTile(
              value: _isAvailable ?? false,
              onChanged: (ambulance == null || hasActiveTrip)
                  ? null
                  : _toggleAvailability,
              title: Text(
                _isAvailable == true ? 'Disponible' : 'Indisponible',
              ),
              subtitle: Text(
                hasActiveTrip
                    ? 'Terminez l\'intervention en cours avant de basculer'
                    : _isAvailable == true
                        ? 'Position GPS envoyée toutes les 10 s'
                        : 'Activez pour recevoir les demandes',
              ),
              secondary: Icon(
                _isAvailable == true
                    ? Icons.check_circle
                    : Icons.pause_circle,
                color: _isAvailable == true
                    ? AppColors.success
                    : AppColors.offline,
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 16),
          if (ambulance != null)
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.local_hospital,
                  color: AppColors.active,
                ),
                title: const Text('Votre véhicule'),
                subtitle: Text(
                  '${ambulance['plate_number']} — ${ambulance['model']}',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
