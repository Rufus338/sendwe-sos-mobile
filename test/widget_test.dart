// Test de fumée : l'app Sendwe SOS démarre sur l'écran de connexion.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sendwe_sos/main.dart';

void main() {
  testWidgets('L app démarre sur le splash', (WidgetTester tester) async {
    await tester.pumpWidget(const SendweSosApp());
    await tester.pump();
    // Le splash affiche un indicateur de chargement
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });
}
