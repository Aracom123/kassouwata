import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/di/injection.dart';

/// Les trois espaces de l'application KASUWATA My Buz.
///
/// Chaque espace est une sous-application avec ses propres onglets :
/// - Acheteur : boutique en ligne (catalogue, panier, achats) ;
/// - Vendeur : gestion de la boutique (tableau de bord, produits, commandes) ;
/// - Adashen Waya : les Adashé (tontines).
/// Un compte Client accède aux espaces Acheteur et Adashen Waya ; un compte
/// Vendeur accède aux trois.
enum Espace {
  acheteur(
    nom: 'Acheteur',
    description: 'Acheter des produits, payer en une fois ou par tranches',
    accueil: '/home',
    icone: Icons.shopping_bag_outlined,
  ),
  vendeur(
    nom: 'Vendeur',
    description: 'Gérer ma boutique, mes produits et mes commandes',
    accueil: '/vendeur',
    icone: Icons.storefront_outlined,
  ),
  adashe(
    nom: 'Adashen Waya',
    description: 'Créer ou rejoindre un Adashé et cotiser',
    accueil: '/adashe',
    icone: Icons.groups_outlined,
  );

  final String nom;
  final String description;
  final String accueil;
  final IconData icone;

  const Espace({
    required this.nom,
    required this.description,
    required this.accueil,
    required this.icone,
  });
}

/// Mémorise le dernier espace ouvert : l'application y revient au lancement.
class EspaceService {
  static const _cle = 'espace_courant';

  static SharedPreferences get _prefs => getIt<SharedPreferences>();

  static Espace? dernier() {
    final nom = _prefs.getString(_cle);
    for (final e in Espace.values) {
      if (e.name == nom) return e;
    }
    return null;
  }

  static Future<void> memoriser(Espace espace) async {
    if (_prefs.getString(_cle) != espace.name) {
      await _prefs.setString(_cle, espace.name);
    }
  }

  /// Page d'arrivée : le dernier espace utilisé, sinon l'écran de choix.
  static String accueil() => dernier()?.accueil ?? '/espaces';
}
