import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../vendeur/vendeur_session.dart';

/// Barre de navigation principale.
///
/// Le profil de l'utilisateur connecté décide des onglets :
/// - CLIENT  : Accueil | Catégories | Boutiques | Tontines | Mes achats
/// - VENDEUR : Accueil | Boutiques | Tontines | Mes achats | Ma boutique
///   (les catégories restent accessibles depuis l'accueil).
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _client = [
    _Onglet('/home', 'Accueil', Icons.home_outlined, Icons.home),
    _Onglet('/categories', 'Catégories', Icons.category_outlined, Icons.category),
    _Onglet('/boutiques', 'Boutiques', Icons.storefront_outlined, Icons.storefront),
    _Onglet('/tontines', 'Tontines', Icons.groups_outlined, Icons.groups),
    _Onglet('/orders', 'Mes achats', Icons.receipt_long_outlined, Icons.receipt_long),
  ];

  static const _vendeur = [
    _Onglet('/home', 'Accueil', Icons.home_outlined, Icons.home),
    _Onglet('/boutiques', 'Boutiques', Icons.storefront_outlined, Icons.storefront),
    _Onglet('/tontines', 'Tontines', Icons.groups_outlined, Icons.groups),
    _Onglet('/orders', 'Mes achats', Icons.receipt_long_outlined, Icons.receipt_long),
    _Onglet('/ma-boutique', 'Ma boutique', Icons.store_mall_directory_outlined,
        Icons.store_mall_directory),
  ];

  int _currentIndex(List<_Onglet> onglets, String location) {
    for (var i = onglets.length - 1; i > 0; i--) {
      if (location.startsWith(onglets[i].route)) return i;
    }
    return 0; // /home (et pages sans onglet propre)
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (a, b) => b is Authenticated || b is Unauthenticated,
      builder: (context, state) {
        final vendeur = state is Authenticated &&
            VendeurSession.estVendeur(state.user.profile);
        final onglets = vendeur ? _vendeur : _client;
        final currentIndex = _currentIndex(onglets, location);

        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) => context.go(onglets[index].route),
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
      },
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
