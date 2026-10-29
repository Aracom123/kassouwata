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
import '../espaces/espace.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../core/widgets/connexion_requise.dart';
import '../espaces/espace_menu.dart';

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
  Future<_Etat>? _etat;

  /// Compte pour lequel [_etat] a été chargé (identifiant + profil) : la
  /// boutique est relue à chaque connexion, déconnexion ou changement de profil.
  String? _cle;

  Future<_Etat> _charger({required bool vendeur, bool rafraichir = true}) async {
    if (!vendeur) return const _Etat.nonVendeur();
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

  void _recharger() => setState(() => _cle = null);

  @override
  Widget build(BuildContext context) {
    // L'état de connexion vient directement de l'AuthBloc : la page se met à
    // jour dès la connexion, sans dépendre d'un chargement mis en cache.
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (a, b) =>
          b is Authenticated || b is Unauthenticated || b is KycPending,
      builder: (context, auth) {
        if (auth is! Authenticated) {
          _cle = null;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Espace Vendeur'),
              leading: const BoutonMenu(),
            ),
            body: const ConnexionRequise(
              titre: 'Espace Vendeur',
              texte: 'Connectez-vous pour gérer votre boutique, vos produits et vos commandes.',
              redirectTo: '/vendeur',
            ),
          );
        }
        final cle = '${auth.user.idUser}|${auth.user.profile}';
        if (cle != _cle || _etat == null) {
          _cle = cle;
          _etat = _charger(vendeur: VendeurSession.estVendeur(auth.user.profile));
        }
        return _contenu(context);
      },
    );
  }

  Widget _contenu(BuildContext context) {
    return FutureBuilder<_Etat>(
      future: _etat!,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          debugPrint('[MaBoutique] Chargement impossible : ${snap.error}');
          return _Message(
            icon: Icons.wifi_off_outlined,
            titre: 'Impossible de charger votre boutique',
            texte: 'Vérifiez votre connexion puis réessayez.',
            action: 'Réessayer',
            onAction: _recharger,
            actionSecondaire: 'Aller à l\'espace Acheteur',
            onActionSecondaire: () => context.go(Espace.acheteur.accueil),
          );
        }
        final etat = snap.data!;
        if (etat.nonVendeur || etat.sansBoutique) {
          return _Message(
            icon: Icons.storefront_outlined,
            titre: etat.nonVendeur
                ? 'Devenez vendeur'
                : 'Vous n\'avez pas encore de boutique',
            texte: etat.nonVendeur
                ? 'Créez votre boutique pour vendre vos produits sur KASUWATA. '
                    'Vous gardez votre accès Acheteur et Adashen Waya.'
                : 'Créez votre boutique pour publier vos produits et recevoir des commandes.',
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
  final String? actionSecondaire;
  final VoidCallback? onActionSecondaire;

  const _Message({
    required this.icon,
    required this.titre,
    required this.texte,
    required this.action,
    required this.onAction,
    this.actionSecondaire,
    this.onActionSecondaire,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Vendeur'),
        leading: const BoutonMenu(),
      ),
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
              if (actionSecondaire != null) ...[
                const SizedBox(height: 8),
                TextButton(
                    onPressed: onActionSecondaire,
                    child: Text(actionSecondaire!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
