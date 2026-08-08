// Tests widget des composants partagés (section 26 — tests widgets/composants).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:sendwe_sos/shared/widgets.dart';
import 'package:sendwe_sos/shared/call_phone.dart';
import 'package:sendwe_sos/shared/sos_map.dart';

void main() {
  group('StatusBadge', () {
    testWidgets('affiche le libellé français du statut', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StatusBadge('AVAILABLE'))),
      );
      expect(find.text('Disponible'), findsOneWidget);
    });

    testWidgets('affiche le statut brut si inconnu', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StatusBadge('UNKNOWN_STATE'))),
      );
      expect(find.text('UNKNOWN STATE'), findsOneWidget);
    });
  });

  group('CallButton', () {
    testWidgets('affiche le label générique et masque le numéro par défaut', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CallButton(phone: '+243820000002')),
        ),
      );
      expect(find.text('Appeler'), findsOneWidget);
      expect(find.text('+243820000002'), findsNothing); // numéro masqué
    });

    testWidgets('affiche le numéro si showNumber', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CallButton(phone: '+243820000002', showNumber: true),
          ),
        ),
      );
      expect(find.text('+243820000002'), findsOneWidget);
    });
  });

  group('SOSMap', () {
    testWidgets('rend la carte avec marqueurs sans erreur', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: SOSMap(
                markers: [
                  MapMarkerData(
                    id: 'ambulance',
                    point: LatLng(-11.66, 27.48),
                    color: Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
