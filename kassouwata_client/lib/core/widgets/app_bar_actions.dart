import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/cart/presentation/bloc/cart_bloc.dart';

/// Actions réutilisables dans les AppBar : icône panier avec badge.
/// (Le menu — profil, à propos, déconnexion — est le menu burger de l'espace.)
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
  ];
}
