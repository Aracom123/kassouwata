import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';

/// Actions réutilisables dans les AppBar : icône panier avec badge + menu burger.
List<Widget> buildAppBarActions(BuildContext context) {
  return [
    BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        final count = cartState.items
            .fold<int>(0, (sum, item) => sum + item.quantity);
        return IconButton(
          tooltip: 'Panier',
          onPressed: () => context.push('/cart'),
          icon: count == 0
              ? const Icon(Icons.shopping_cart_outlined)
              : badges.Badge(
                  badgeContent: Text(
                    '$count',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
        );
      },
    ),
    BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final isAuth = authState is Authenticated;
        return PopupMenuButton<String>(
          icon: const Icon(Icons.menu),
          tooltip: 'Menu',
          onSelected: (value) {
            switch (value) {
              case 'login':
                context.push('/login');
              case 'register':
                context.push('/register');
              case 'orders':
                context.go('/orders');
              case 'profile':
                context.go('/profile');
              case 'about':
                context.push('/about');
              case 'cgu':
                context.push('/cgu');
              case 'logout':
                context.read<AuthBloc>().add(const LogoutRequested());
            }
          },
          itemBuilder: (ctx) => [
                // Actions utilisateur (connecté)
                if (isAuth) ...[
                  const PopupMenuItem(
                    value: 'orders',
                    child: ListTile(
                      leading: Icon(Icons.receipt_long_outlined),
                      title: Text('Mes achats'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'profile',
                    child: ListTile(
                      leading: Icon(Icons.person_outline),
                      title: Text('Mon profil'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                ],
                // Actions utilisateur (non connecté)
                if (!isAuth) ...[
                  const PopupMenuItem(
                    value: 'login',
                    child: ListTile(
                      leading: Icon(Icons.login),
                      title: Text('Se connecter'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'register',
                    child: ListTile(
                      leading: Icon(Icons.person_add_outlined),
                      title: Text('Créer un compte'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                ],
                // Séparateur
                const PopupMenuDivider(),
                // Pages institutionnelles (toujours visibles)
                const PopupMenuItem(
                  value: 'about',
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('À propos'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'cgu',
                  child: ListTile(
                    leading: Icon(Icons.description_outlined),
                    title: Text('CGU'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                // Déconnexion (connecté uniquement)
                if (isAuth) ...[
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout, color: Colors.red),
                      title: Text('Se déconnecter',
                          style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                ],
              ],
        );
      },
    ),
  ];
}
