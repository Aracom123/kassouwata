import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../espaces/espace_auth.dart';

/// Bloc « connexion requise », identique dans toute l'application :
/// Se connecter, Créer un compte et Mot de passe oublié.
class ConnexionRequise extends StatelessWidget {
  final String titre;
  final String texte;
  /// Page à ouvrir après la connexion (ex. '/orders', '/vendeur').
  final String redirectTo;
  final IconData? icone;

  const ConnexionRequise({
    super.key,
    required this.titre,
    required this.texte,
    required this.redirectTo,
    this.icone,
  });

  @override
  Widget build(BuildContext context) {
    final espace = espaceVise(redirectTo);
    final couleur = espace.couleur(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EnteteAuth(
              espace: espace,
              icone: icone,
              titre: titre,
              sousTitre: texte,
            ),
            FilledButton.icon(
              onPressed: () => context.push('/login', extra: redirectTo),
              icon: const Icon(Icons.login),
              label: const Text('Se connecter'),
              style: FilledButton.styleFrom(
                  backgroundColor: couleur,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/register', extra: redirectTo),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Créer un compte'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: couleur,
                  side: BorderSide(color: couleur),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => context.push('/forgot-password'),
              child: const Text('Mot de passe oublié ?'),
            ),
          ],
        ),
      ),
    );
  }
}
