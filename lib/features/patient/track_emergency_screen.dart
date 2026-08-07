/// P4 — Suivi d'intervention en temps réel (section 9.B).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/ws_client.dart';
import '../../shared/sos_map.dart';
import '../../shared/widgets.dart';
import 'summary_screen.dart';

class TrackEmergencyScreen extends StatefulWidget {
  final String emergencyId;
  const TrackEmergencyScreen({super.key, required this.emergencyId});

  @override
  State<TrackEmergencyScreen> createState() => _TrackEmergencyScreenState();
}

class _TrackEmergencyScreenState extends State<TrackEmergencyScreen> {
  Map<String, dynamic>? _trip;
  String? _status;
  LatLng? _ambulancePosition;
  bool _completed = false;
  bool _cancelled = false;
  WSClient? _ws;

  @override
  void initState() {
    super.initState();
    _load();
    _ws = WSClient(
      handlers: {
        'ambulance.location.updated': (data) {
          final lat = (data['lat'] as num?)?.toDouble();
          final lng = (data['lng'] as num?)?.toDouble();
          if (lat != null && lng != null && mounted) {
            setState(() => _ambulancePosition = LatLng(lat, lng));
          }
        },
        'emergency.status.updated': (data) {
          final status = data['status'] as String?;
          if (status == 'COMPLETED') _goToSummary();
          if (status == 'CANCELLED') setState(() => _cancelled = true);
          setState(() => _status = status);
        },
      },
    );
    _ws!.connect();
  }

  Future<void> _load() async {
    try {
      // Vue patient scoped (décision 12) : uniquement SON ambulance affectée
      final view =
          await apiClient.get('/trips/active-for/${widget.emergencyId}')
              as Map<String, dynamic>?;
      if (view != null) {
        final amb = view['ambulance'] as Map<String, dynamic>?;
        final loc = amb?['location'] as Map<String, dynamic>?;
        if (loc != null) {
          final lat = (loc['lat'] as num).toDouble();
          final lng = (loc['lng'] as num).toDouble();
          if (mounted) {
            setState(() {
              _status = view['status'] as String?;
              _ambulancePosition = LatLng(lat, lng);
            });
          }
        }
      }
    } catch (_) {
      /* ignore */
    }
  }

  void _goToSummary() {
    _ws?.close();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SummaryScreen(emergencyId: widget.emergencyId),
        ),
      );
    }
  }

  Future<void> _cancel() async {
    try {
      await apiClient.patch(
        '/emergencies/${widget.emergencyId}/cancel',
        body: {'reason': 'Annulé par le patient'},
      );
    } catch (_) {
      /* ignore */
    }
  }

  @override
  void dispose() {
    _ws?.close();
    super.dispose();
  }

  bool get _canCancel {
    final s = _status;
    if (s == null || _cancelled || _completed) return false;
    // Annulation possible avant PATIENT_PICKED_UP
    const cutOff = [
      'PATIENT_PICKED_UP',
      'EN_ROUTE_TO_HOSPITAL',
      'ARRIVED_AT_HOSPITAL',
      'COMPLETED',
      'CANCELLED',
    ];
    return !cutOff.contains(s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suivi de l\'ambulance')),
      body: _cancelled
          ? const Center(child: Text('Cette demande a été annulée'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _status != null
                      ? StatusBadge(_status!)
                      : const LoadingView(),
                ),
                // Carte : position de l'ambulance (section 19)
                Expanded(
                  child: _ambulancePosition != null
                      ? SOSMap(
                          center: _ambulancePosition,
                          markers: [
                            MapMarkerData(
                              id: 'ambulance',
                              point: _ambulancePosition!,
                              color: ambulanceMarkerColor,
                            ),
                          ],
                          interactive: true,
                        )
                      : const ColoredBox(
                          color: Color(0xFFE8EEF5),
                          child: Center(
                            child: Icon(
                              Icons.local_taxi,
                              size: 64,
                              color: AppColors.active,
                            ),
                          ),
                        ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (_canCancel)
                          OutlinedButton(
                            onPressed: () => showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Annuler la demande'),
                                content: const Text(
                                  'Voulez-vous vraiment annuler ?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Non'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _cancel();
                                    },
                                    child: const Text('Oui, annuler'),
                                  ),
                                ],
                              ),
                            ),
                            child: const Text('Annuler'),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
