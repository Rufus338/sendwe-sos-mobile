/// P1 — Accueil patient (section 9.B).

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../shared/sos_map.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import 'new_emergency_screen.dart';
import 'track_emergency_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _index = 0;
  LatLng? _position;
  bool _gpsError = false;

  @override
  void initState() {
    super.initState();
    _locate();
  }

  Future<void> _locate() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _position = LatLng(pos.latitude, pos.longitude);
          _gpsError = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _gpsError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          _HomeTab(
            position: _position,
            gpsError: _gpsError,
            onRetry: _locate,
            onNewRequest: () async {
              // P1 → P2 : vérifier qu'aucune demande active (redirection automatique sinon)
              final active = await _activeEmergency();
              if (!mounted) return;
              if (active != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TrackEmergencyScreen(
                      emergencyId: active['id'] as String,
                    ),
                  ),
                );
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NewEmergencyScreen()),
                );
              }
            },
          ),
          const HistoryScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Historique'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _activeEmergency() async {
    try {
      final data =
          await apiClient.get('/emergencies/active') as Map<String, dynamic>?;
      return data;
    } catch (_) {
      return null;
    }
  }
}

class _HomeTab extends StatelessWidget {
  final LatLng? position;
  final bool gpsError;
  final VoidCallback onRetry;
  final Future<void> Function() onNewRequest;
  const _HomeTab({
    required this.position,
    required this.gpsError,
    required this.onRetry,
    required this.onNewRequest,
  });

  @override
  Widget build(BuildContext context) {
    final markers = <MapMarkerData>[
      if (position != null)
        MapMarkerData(
          id: 'patient',
          point: position!,
          color: patientMarkerColor,
        ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Carte centrée sur la position actuelle (P1, section 19)
          if (position != null)
            SOSMap(center: position, markers: markers, interactive: true)
          else
            const ColoredBox(
              color: Color(0xFFE8EEF5),
              child: Center(
                child: Icon(Icons.location_off, size: 80, color: Colors.grey),
              ),
            ),
          // Bannière d'erreur GPS avec saisie manuelle en secours (P1)
          if (gpsError)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                color: AppColors.pending,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Impossible de déterminer votre position',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: onRetry,
                        child: const Text(
                          'Réessayer',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onNewRequest,
                  icon: const Icon(Icons.local_hospital, size: 24),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Demander une ambulance',
                      style: TextStyle(fontSize: 17),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
