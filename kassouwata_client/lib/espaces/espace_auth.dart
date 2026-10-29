import 'package:flutter/material.dart';

import 'espace.dart';

/// Habillage des écrans de connexion selon l'espace visé.
extension EspaceAuth on Espace {
  /// Couleur de l'espace (la même sur l'écran de choix et sur la connexion).
  Color couleur(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (this) {
      case Espace.acheteur:
        return scheme.primary;
      case Espace.vendeur:
        return scheme.secondary;
      case Espace.adashe:
        return const Color(0xFFE8862A);
    }
  }

  String get accroche {
    switch (this) {
      case Espace.acheteur:
        return 'Achetez et suivez vos commandes';
      case Espace.vendeur:
        return 'Gérez votre boutique, vos produits et vos commandes';
      case Espace.adashe:
        return 'Créez ou rejoignez un Adashé et cotisez';
    }
  }
}

/// Espace visé par un écran de connexion : déduit de la page à ouvrir après
/// la connexion, sinon le dernier espace utilisé, sinon Acheteur.
Espace espaceVise([String? redirectTo]) {
  final r = redirectTo ?? '';
  if (r.startsWith('/vendeur') || r.startsWith('/creer-boutique')) {
    return Espace.vendeur;
  }
  if (r.startsWith('/tontines') || r.startsWith('/adashe')) {
    return Espace.adashe;
  }
  if (r.startsWith('/home') ||
      r.startsWith('/orders') ||
      r.startsWith('/checkout') ||
      r.startsWith('/cart') ||
      r.startsWith('/products') ||
      r.startsWith('/boutiques') ||
      r.startsWith('/categories')) {
    return Espace.acheteur;
  }
  return EspaceService.dernier() ?? Espace.acheteur;
}

/// En-tête commun à tous les écrans d'authentification (connexion, création
/// de compte, mot de passe oublié, code SMS, connexion requise).
class EnteteAuth extends StatelessWidget {
  final Espace espace;
  final String titre;
  final String? sousTitre;
  /// Icône à la place de celle de l'espace (ex. cadenas pour le mot de passe).
  final IconData? icone;

  const EnteteAuth({
    super.key,
    required this.espace,
    required this.titre,
    this.sousTitre,
    this.icone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = espace.couleur(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: CircleAvatar(
            radius: 36,
            backgroundColor: c,
            child: Icon(icone ?? espace.icone, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'KASUWATA My Buz · ${espace.nom}',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: c, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(titre,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        if (sousTitre != null) ...[
          const SizedBox(height: 6),
          Text(sousTitre!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey.shade700)),
        ],
        const SizedBox(height: 28),
      ],
    );
  }
}
