import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../vendeur/vendeur_session.dart';
import 'espace.dart';
import 'espace_auth.dart';

/// Écran d'accueil : choix de l'espace (Acheteur, Vendeur, Adashen Waya).
class EspacesPage extends StatelessWidget {
  const EspacesPage({super.key});

  Future<void> _ouvrir(BuildContext context, Espace espace) async {
    await EspaceService.memoriser(espace);
    if (!context.mounted) return;
    final connecte = context.read<AuthBloc>().state is Authenticated;
    if (!connecte && espace != Espace.acheteur) {
      // Vendeur et Adashen Waya demandent un compte : connexion d'abord,
      // puis ouverture directe de l'espace choisi.
      context.push('/login', extra: espace.accueil);
      return;
    }
    context.go(espace.accueil);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, auth) {
        final connecte = auth is Authenticated;
        final vendeur =
            connecte && VendeurSession.estVendeur(auth.user.profile);
        final prenom = connecte ? (auth.user.prenom ?? '') : '';

        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                // ── En-tête ──────────────────────────────────────────────
                Text('KASUWATA',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: theme.colorScheme.primary,
                    )),
                Text('My Buz',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: Colors.grey.shade700)),
                const SizedBox(height: 20),
                Text(
                  prenom.isNotEmpty
                      ? 'Bonjour $prenom, que voulez-vous faire ?'
                      : 'Que voulez-vous faire ?',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),

                // ── Les trois espaces ────────────────────────────────────
                for (final e in Espace.values) ...[
                  _CarteEspace(
                    espace: e,
                    couleur: e.couleur(context),
                    mention: e == Espace.vendeur && connecte && !vendeur
                        ? 'Devenir vendeur'
                        : null,
                    onTap: () => _ouvrir(context, e),
                  ),
                  const SizedBox(height: 14),
                ],

              ],
            ),
          ),
        );
      },
    );
  }
}

class _CarteEspace extends StatelessWidget {
  final Espace espace;
  final Color couleur;
  final String? mention;
  final VoidCallback onTap;

  const _CarteEspace({
    required this.espace,
    required this.couleur,
    required this.onTap,
    this.mention,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: couleur.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: couleur,
                child: Icon(espace.icone, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(espace.nom,
                        style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold, color: couleur)),
                    const SizedBox(height: 4),
                    Text(mention ?? espace.description,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.grey.shade800)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: couleur),
            ],
          ),
        ),
      ),
    );
  }
}
