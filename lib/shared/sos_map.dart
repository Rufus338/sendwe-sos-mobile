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

/// Carte de sélection d'un point : le pin est fixé au centre, on déplace la
/// carte pour ajuster la position (section P2 — pickup_location éditable).
class SOSPointPicker extends StatefulWidget {
  final LatLng? initial;
  final ValueChanged<LatLng> onChanged;

  const SOSPointPicker({
    super.key,
    this.initial,
    required this.onChanged,
  });

  @override
  State<SOSPointPicker> createState() => _SOSPointPickerState();
}

class _SOSPointPickerState extends State<SOSPointPicker> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onMove() {
    final center = _mapController.camera.center;
    widget.onChanged(center);
  }

  @override
  Widget build(BuildContext context) {
    final initial =
        widget.initial ?? const LatLng(-11.6647, 27.4794); // Lubumbashi
    return Stack(
      alignment: Alignment.center,
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initial,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.doubleTapZoom,
            ),
            onPositionChanged: (_, __) => _onMove(),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.sendwe.sendwe_sos',
            ),
          ],
        ),
        // Pin central fixe (le point sélectionné = centre de la carte)
        const IgnorePointer(
          child: Icon(
            Icons.location_pin,
            size: 44,
            color: AppColors.danger,
          ),
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
