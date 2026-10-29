import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kassouwata_client/espaces/espace.dart';

void main() {
  test('Les trois espaces de KASUWATA My Buz', () {
    expect(Espace.values.map((e) => e.nom),
        ['Acheteur', 'Vendeur', 'Adashen Waya']);
    expect(Espace.acheteur.accueil, '/home');
    expect(Espace.vendeur.accueil, '/vendeur');
    expect(Espace.adashe.accueil, '/adashe');
    expect(Espace.adashe.icone, isA<IconData>());
  });
}
