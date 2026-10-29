import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../vendeur/vendeur_session.dart';
import 'espace.dart';
import 'espace_auth.dart';

/// Menu burger (tiroir latéral) commun aux trois espaces :
/// Mon profil, Ma boutique et Achats groupés (vendeur), Mes espaces, À propos, Se déconnecter.
class EspaceMenu extends StatelessWidget {
  final Espace espace;
  const EspaceMenu({super.key, required this.espace});

  void _fermerPuis(BuildContext context, void Function() action) {
    Navigator.of(context).pop(); // ferme le menu
    action();
  }

  Future<void> _deconnecter(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Se déconnecter')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    context.read<AuthBloc>().add(const LogoutRequested());
    context.go('/espaces');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleur = espace.couleur(context);

    return Drawer(
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, auth) {
          final connecte = auth is Authenticated;
          final user = connecte ? auth.user : null;
          final vendeur = user != null && VendeurSession.estVendeur(user.profile);
          final nom = user == null
              ? 'Non connecté'
              : [user.prenom, user.nom]
                  .whereType<String>()
                  .where((s) => s.isNotEmpty)
                  .join(' ');

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              // ── En-tête ──
              Container(
                color: couleur,
                padding: EdgeInsets.fromLTRB(
                    20, MediaQuery.of(context).padding.top + 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Text(
                        nom.isNotEmpty && connecte ? nom[0].toUpperCase() : '?',
                        style: TextStyle(
                            color: couleur,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(nom.isEmpty ? (user?.telephone ?? '') : nom,
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    if (user != null)
                      Text(user.telephone,
                          style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'KASUWATA My Buz · ${espace.nom}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Compte ──
              if (connecte) ...[
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Mon profil'),
                  onTap: () => _fermerPuis(context, () => context.push('/profile')),
                ),
                if (vendeur)
                  ListTile(
                    leading: const Icon(Icons.store_outlined),
                    title: const Text('Ma boutique'),
                    onTap: () =>
                        _fermerPuis(context, () => context.push('/vendeur/boutique')),
                  ),
                if (vendeur)
                  ListTile(
                    leading: const Icon(Icons.groups_outlined),
                    title: const Text('Achats groupés (Adashé)'),
                    onTap: () =>
                        _fermerPuis(context, () => context.push('/vendeur/adashe')),
                  ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.login),
                  title: const Text('Se connecter'),
                  onTap: () => _fermerPuis(
                      context, () => context.push('/login', extra: espace.accueil)),
                ),
                ListTile(
                  leading: const Icon(Icons.person_add_outlined),
                  title: const Text('Créer un compte'),
                  onTap: () => _fermerPuis(context,
                      () => context.push('/register', extra: espace.accueil)),
                ),
              ],
              const Divider(),
              ListTile(
                leading: const Icon(Icons.apps),
                title: const Text('Mes espaces'),
                onTap: () => _fermerPuis(context, () => context.push('/espaces')),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('À propos'),
                onTap: () => _fermerPuis(context, () => context.push('/about')),
              ),
              if (connecte) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Se déconnecter',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _deconnecter(context);
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Bouton à gauche de la barre de titre des pages d'onglet : ouvre le menu
/// burger de l'espace. Sur une page ouverte par-dessus, c'est un bouton retour.
class BoutonMenu extends StatelessWidget {
  const BoutonMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final ouvrir = MenuEspace.maybeOf(context);
    if (ouvrir != null && !Navigator.of(context).canPop()) {
      return IconButton(
        tooltip: 'Menu',
        icon: const Icon(Icons.menu),
        onPressed: ouvrir,
      );
    }
    if (Navigator.of(context).canPop()) return const BackButton();
    return const SizedBox.shrink();
  }
}

/// Transmet aux pages d'un espace la fonction qui ouvre son menu burger.
class MenuEspace extends InheritedWidget {
  final VoidCallback ouvrir;
  const MenuEspace({super.key, required this.ouvrir, required super.child});

  static VoidCallback? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MenuEspace>()?.ouvrir;

  @override
  bool updateShouldNotify(MenuEspace oldWidget) => false;
}
