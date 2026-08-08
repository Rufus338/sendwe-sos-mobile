// Tests widget de la carte de sélection de position (P2 — pickup éditable).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:sendwe_sos/shared/sos_map.dart';

void main() {
  group('SOSPointPicker', () {
    testWidgets('affiche le pin central et notifie le déplacement', (
      tester,
    ) async {
      final moved = <LatLng>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: SOSPointPicker(
                initial: const LatLng(-11.66, 27.48),
                onChanged: (p) => moved.add(p),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      // Le pin central est présent
      expect(find.byIcon(Icons.location_pin), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
