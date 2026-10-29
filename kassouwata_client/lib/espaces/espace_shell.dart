import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../vendeur/vendeur_session.dart';

import 'espace.dart';
import 'espace_menu.dart';

/// Barre d'onglets propre à chaque espace. Le dernier onglet, « Espaces »,
/// ramène à l'écran de choix pour changer d'espace.
class EspaceShell extends StatefulWidget {
  final Espace espace;
  final Widget child;
  const EspaceShell({super.key, required this.espace, required this.child});

  @override
  State<EspaceShell> createState() => _EspaceShellState();
}

class _EspaceShellState extends State<EspaceShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Espace get espace => widget.espace;
  Widget get child => widget.child;

  /// Scaffold de l'espace : menu burger commun, barre d'onglets si fournie.
  Widget _scaffold(Widget? barre) {
    return MenuEspace(
      ouvrir: () => _scaffoldKey.currentState?.openDrawer(),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: EspaceMenu(espace: espace),
        body: child,
        bottomNavigationBar: barre,
      ),
    );
  }

  static const _espaces = _Onglet('/espaces', 'Espaces', Icons.apps_outlined, Icons.apps);

  static const Map<Espace, List<_Onglet>> _onglets = {
    Espace.acheteur: [
      _Onglet('/home', 'Accueil', Icons.home_outlined, Icons.home),
      _Onglet('/categories', 'Catégories', Icons.category_outlined, Icons.category),
      _Onglet('/boutiques', 'Boutiques', Icons.storefront_outlined, Icons.storefront),
      _Onglet('/orders', 'Mes achats', Icons.receipt_long_outlined, Icons.receipt_long),
      _espaces,
    ],
    Espace.vendeur: [
      _Onglet('/vendeur', 'Dashboard', Icons.dashboard_outlined, Icons.dashboard),
      _Onglet('/vendeur/produits', 'Produits', Icons.inventory_2_outlined, Icons.inventory_2),
      _Onglet('/vendeur/commandes', 'Commandes', Icons.receipt_long_outlined, Icons.receipt_long),
      _espaces,
    ],
    Espace.adashe: [
      _Onglet('/adashe', 'Dashboard', Icons.dashboard_outlined, Icons.dashboard),
      _Onglet('/tontines', 'Mes Adashé', Icons.groups_outlined, Icons.groups),
      _Onglet('/adashe/compte', 'Mon compte', Icons.person_outline, Icons.person),
      _espaces,
    ],
  };

  int _index(List<_Onglet> onglets, String location) {
    // Le plus long préfixe gagne (/vendeur/produits avant /vendeur)
    var meilleur = 0;
    var longueur = -1;
    for (var i = 0; i < onglets.length; i++) {
      final r = onglets[i].route;
      if ((location == r || location.startsWith('$r/')) && r.length > longueur) {
        meilleur = i;
        longueur = r.length;
      }
    }
    return meilleur;
  }

  /// Bouton retour du téléphone : depuis un onglet, retour à l'accueil de
  /// l'espace ; depuis l'accueil de l'espace, retour à « Mes espaces ».
  /// (Les pages ouvertes par-dessus un onglet reviennent normalement en arrière.)
  Widget _retour(BuildContext context, Widget contenu) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final location = GoRouterState.of(context).uri.path;
        if (location != espace.accueil) {
          context.go(espace.accueil);
        } else {
          context.go('/espaces');
        }
      },
      child: contenu,
    );
  }

  @override
  Widget build(BuildContext context) => _retour(context, _construire(context));

  Widget _construire(BuildContext context) {
    EspaceService.memoriser(espace);
    if (espace == Espace.vendeur) {
      // Pas d'onglets vendeur tant que le compte n'est pas un compte vendeur :
      // la page affiche seulement « Se connecter » ou « Devenez vendeur ».
      return BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (a, b) =>
            b is Authenticated || b is Unauthenticated || b is KycPending,
        builder: (context, auth) {
          final vendeur = auth is Authenticated &&
              VendeurSession.estVendeur(auth.user.profile);
          return vendeur ? _avecOnglets(context) : _scaffold(null);
        },
      );
    }
    return _avecOnglets(context);
  }

  Widget _avecOnglets(BuildContext context) {
    final onglets = _onglets[espace]!;
    final location = GoRouterState.of(context).uri.path;

    return _scaffold(NavigationBar(
        selectedIndex: _index(onglets, location),
        onDestinationSelected: (i) {
          final route = onglets[i].route;
          if (route == '/espaces') {
            // Ouvert par-dessus l'espace : le retour y ramène
            context.push(route);
          } else {
            context.go(route);
          }
        },
        destinations: [
          for (final o in onglets)
            NavigationDestination(
              icon: Icon(o.icon),
              selectedIcon: Icon(o.selectedIcon),
              label: o.label,
            ),
        ],
      ),
    );
  }
}

class _Onglet {
  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const _Onglet(this.route, this.label, this.icon, this.selectedIcon);
}
