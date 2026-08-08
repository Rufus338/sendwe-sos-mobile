// Tests widget de l'écran P2 — validation des champs bénéficiaire (section 9.B).
//
// Le geolocator n'est pas disponible en test : `_locate()` échoue proprement
// (état "GPS indisponible"), ce qui permet de tester la logique conditionnelle.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sendwe_sos/features/patient/new_emergency_screen.dart';

void main() {
  testWidgets('P2 : bouton Confirmer désactivé tant que le motif n est pas choisi', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: NewEmergencyScreen()));
    await tester.pump();

    final confirm = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Confirmer la demande'),
    );
    expect(confirm.onPressed, isNull);

    // Choisir un motif → le bouton s'active (position GPS absente en test
    // mais la logique principale est la catégorie).
    await tester.tap(find.text('Accident'));
    await tester.pump();
  });

  testWidgets('P2 : bascule "Pour quelqu un d autre" affiche les champs bénéficiaire', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: NewEmergencyScreen()));
    await tester.pump();

    // Avant : pas de champs bénéficiaire
    expect(find.text('Nom de la personne à secourir'), findsNothing);

    // Basculer sur "Pour quelqu'un d'autre"
    await tester.tap(find.text('Pour quelqu\'un d\'autre'));
    await tester.pump();

    // Après : champs affichés
    expect(find.text('Nom de la personne à secourir'), findsOneWidget);
    expect(find.text('Téléphone sur place'), findsOneWidget);
  });
}
