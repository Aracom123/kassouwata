import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/cart_bloc.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon panier'),
        actions: [
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              if (state.items.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => context.read<CartBloc>().add(const ClearCart()),
                child: const Text('Vider'),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Votre panier est vide',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          final baseUrl = dotenv.env['BASE_URL'] ?? '';

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    final product = item.product;
                    final imageUrl = product.imageFilename != null
                        ? '$baseUrl/images/${product.imageFilename}'
                        : null;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: imageUrl != null
                                    ? Image.network(imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Container(
                                              color: theme.colorScheme
                                                  .surfaceContainerHighest,
                                              child: const Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.grey),
                                            ))
                                    : Container(
                                        color: theme.colorScheme
                                            .surfaceContainerHighest,
                                        child: const Icon(Icons.image_outlined,
                                            color: Colors.grey),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.libelle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${product.prix.toStringAsFixed(0)} F',
                                    style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),

                            // Quantity control
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  iconSize: 20,
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => context.read<CartBloc>().add(
                                      UpdateCartQuantity(
                                          product.idProduit, item.quantity - 1)),
                                ),
                                Text('${item.quantity}',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold)),
                                IconButton(
                                  iconSize: 20,
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => context.read<CartBloc>().add(
                                      UpdateCartQuantity(
                                          product.idProduit, item.quantity + 1)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Total + Checkout button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: const Offset(0, -2)),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Total',
                              style: TextStyle(color: Colors.grey)),
                          Text(
                            '${state.total.toStringAsFixed(0)} FCFA',
                            style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, authState) {
                            return FilledButton.icon(
                              onPressed: () {
                                if (authState is! Authenticated) {
                                  context.push('/login', extra: '/checkout');
                                } else {
                                  context.push('/checkout');
                                }
                              },
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Passer la commande'),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
