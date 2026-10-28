import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injection.dart';
import '../core/storage/secure_storage.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/onboarding/presentation/pages/create_boutique_page.dart';
import 'features/shop/data/models/shop_model.dart';
import 'vendeur_session.dart';

/// Onglet « Ma boutique » (profil VENDEUR uniquement).
///
/// Vérifie que le vendeur a une boutique : sinon l'invite à la créer, sinon
/// affiche le tableau de bord (produits, commandes reçues, paramètres).
class MaBoutiquePage extends StatefulWidget {
  const MaBoutiquePage({super.key});

  @override
  State<MaBoutiquePage> createState() => _MaBoutiquePageState();
}

class _MaBoutiquePageState extends State<MaBoutiquePage> {
  final _session = getIt<VendeurSession>();
  late Future<_Etat> _etat;

  @override
  void initState() {
    super.initState();
    // Toujours relire la boutique sur le serveur à l'ouverture de l'onglet :
    // le tableau de bord et les produits utilisent ensuite la bonne boutique.
    _etat = _charger(rafraichir: true);
  }

  Future<_Etat> _charger({bool rafraichir = false}) async {
    if (!await _session.estConnecteCommeVendeur()) return const _Etat.nonVendeur();
    ShopModel? b;
    try {
      b = await _session.boutique(rafraichir: rafraichir);
    } catch (_) {
      // Hors ligne : on se rabat sur la boutique en cache
      if (!rafraichir) rethrow;
      b = await _session.boutique();
    }
    return b == null ? const _Etat.sansBoutique() : const _Etat.ok();
  }

  void _recharger() =>
      setState(() => _etat = _charger(rafraichir: true));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Etat>(
      future: _etat,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return _Message(
            icon: Icons.wifi_off_outlined,
            titre: 'Impossible de charger votre boutique',
            texte: 'Vérifiez votre connexion puis réessayez.',
            action: 'Réessayer',
            onAction: _recharger,
          );
        }
        final etat = snap.data!;
        if (etat.nonVendeur) {
          return _Message(
            icon: Icons.lock_outline,
            titre: 'Espace réservé aux vendeurs',
            texte: 'La gestion de boutique est disponible pour les comptes vendeur.',
            action: 'Retour à l\'accueil',
            onAction: () => context.go('/home'),
          );
        }
        if (etat.sansBoutique) {
          return _Message(
            icon: Icons.storefront_outlined,
            titre: 'Vous n\'avez pas encore de boutique',
            texte: 'Créez votre boutique pour publier vos produits et recevoir des commandes.',
            action: 'Créer ma boutique',
            onAction: () async {
              await context.push('/creer-boutique');
              if (mounted) _recharger();
            },
          );
        }
        return BlocProvider(
          create: (_) => getIt<DashboardBloc>()..add(const LoadDashboard()),
          child: const DashboardPage(),
        );
      },
    );
  }
}

/// Création de la boutique : l'identifiant du vendeur est lu dans la session.
class CreerBoutiquePage extends StatelessWidget {
  const CreerBoutiquePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: getIt<SecureStorage>().getUserId(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final idUser = snap.data;
        if (idUser == null || idUser.isEmpty) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => context.go('/login'));
          return const Scaffold(body: SizedBox.shrink());
        }
        return CreateBoutiquePage(idUser: idUser);
      },
    );
  }
}

class _Etat {
  final bool nonVendeur;
  final bool sansBoutique;
  const _Etat.ok()
      : nonVendeur = false,
        sansBoutique = false;
  const _Etat.nonVendeur()
      : nonVendeur = true,
        sansBoutique = false;
  const _Etat.sansBoutique()
      : nonVendeur = false,
        sansBoutique = true;
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String titre;
  final String texte;
  final String action;
  final VoidCallback onAction;

  const _Message({
    required this.icon,
    required this.titre,
    required this.texte,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ma boutique')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(titre,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(texte,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey.shade700)),
              const SizedBox(height: 24),
              FilledButton(onPressed: onAction, child: Text(action)),
            ],
          ),
        ),
      ),
    );
  }
}
