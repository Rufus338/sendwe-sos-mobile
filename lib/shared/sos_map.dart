/// Carte partagée Flutter — tuiles OpenStreetMap via flutter_map (section 12.2/19).
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme.dart';

class MapMarkerData {
  final String id;
  final LatLng point;
  final Color color;
  const MapMarkerData({
    required this.id,
    required this.point,
    required this.color,
  });
}

/// Carte simple centrée sur un point, avec marqueurs (section 19).
class SOSMap extends StatelessWidget {
  final LatLng? center;
  final List<MapMarkerData> markers;
  final double zoom;
  final bool interactive;

  const SOSMap({
    super.key,
    this.center,
    this.markers = const [],
    this.zoom = 13,
    this.interactive = false,
  });

  @override
  Widget build(BuildContext context) {
    final initialCenter =
        center ?? const LatLng(-11.6647, 27.4794); // Lubumbashi
    return FlutterMap(
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: zoom,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.sendwe.sendwe_sos',
        ),
        MarkerLayer(
          markers: [
            for (final m in markers)
              Marker(
                point: m.point,
                width: 24,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    color: m.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Icône de position du patient (bleu, section 19).
const patientMarkerColor = AppColors.active;

/// Icône de l'ambulance (bleue en intervention, section 19).
const ambulanceMarkerColor = AppColors.active;

/// Point de prise en charge (rouge fixe, section 19).
const pickupMarkerColor = AppColors.danger;
