import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/widgets/app_bar_actions.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/catalogue_repository.dart';
import '../widgets/product_card.dart';

class CategoryProductsPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const CategoryProductsPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  late Future<List<ProductEntity>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _productsFuture = getIt<CatalogueRepository>()
        .getProducts(categorieId: widget.categoryId)
        .then((result) => result.fold(
              (f) => throw f,
              (products) => products,
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: buildAppBarActions(context),
      ),
      body: FutureBuilder<List<ProductEntity>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final msg = snapshot.error is Failure
                ? (snapshot.error as Failure).message
                : snapshot.error.toString();
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(msg),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => setState(_load),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Aucun produit dans cette catégorie',
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
