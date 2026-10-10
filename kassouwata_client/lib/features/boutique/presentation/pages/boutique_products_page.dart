import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_bar_actions.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../catalogue/presentation/widgets/product_card.dart';
import '../bloc/boutique_bloc.dart';

class BoutiqueProductsPage extends StatefulWidget {
  final int boutiqueId;
  final String boutiqueName;

  const BoutiqueProductsPage({
    super.key,
    required this.boutiqueId,
    required this.boutiqueName,
  });

  @override
  State<BoutiqueProductsPage> createState() => _BoutiqueProductsPageState();
}

class _BoutiqueProductsPageState extends State<BoutiqueProductsPage> {
  @override
  void initState() {
    super.initState();
    context
        .read<BoutiqueBloc>()
        .add(LoadBoutiqueProducts(widget.boutiqueId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.boutiqueName),
        actions: buildAppBarActions(context),
      ),
      body: BlocBuilder<BoutiqueBloc, BoutiqueState>(
        buildWhen: (prev, curr) =>
            prev.productsStatus != curr.productsStatus ||
            prev.boutiqueProducts != curr.boutiqueProducts,
        builder: (context, state) {
          if (state.productsStatus == BoutiqueStatus.initial ||
              state.productsStatus == BoutiqueStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.productsStatus == BoutiqueStatus.failure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(state.errorMessage ?? 'Erreur de chargement'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context
                        .read<BoutiqueBloc>()
                        .add(LoadBoutiqueProducts(widget.boutiqueId)),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final products = state.boutiqueProducts;
          if (products.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Aucun produit dans cette boutique',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onTap: () => context.push('/products/${product.idProduit}'),
                onAddToCart: () =>
                    context.read<CartBloc>().add(AddToCart(product)),
              );
            },
          );
        },
      ),
    );
  }
}
