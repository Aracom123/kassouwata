import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_bar_actions.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../bloc/catalogue_bloc.dart';
import '../widgets/product_card.dart';
import '../../../../espaces/espace_menu.dart';

class CataloguePage extends StatefulWidget {
  const CataloguePage({super.key});

  @override
  State<CataloguePage> createState() => _CataloguePageState();
}

class _CataloguePageState extends State<CataloguePage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CatalogueBloc>().add(const LoadCatalogue());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const BoutonMenu(),
        title: const Text('KASUWATA'),
        actions: buildAppBarActions(context),
      ),
      body: BlocBuilder<CatalogueBloc, CatalogueState>(
        builder: (context, state) {
          if ((state.status == CatalogueStatus.initial ||
                  state.status == CatalogueStatus.loading) &&
              state.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == CatalogueStatus.failure) {
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
                        .read<CatalogueBloc>()
                        .add(const LoadCatalogue()),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<CatalogueBloc>().add(const LoadCatalogue()),
            child: CustomScrollView(
              slivers: [
                // Barre de recherche
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: SearchBar(
                      controller: _searchCtrl,
                      hintText: 'Rechercher un produit...',
                      leading: const Icon(Icons.search),
                      trailing: [
                        if (_searchCtrl.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              context
                                  .read<CatalogueBloc>()
                                  .add(const SearchCatalogue(''));
                            },
                          ),
                      ],
                      onChanged: (v) => context
                          .read<CatalogueBloc>()
                          .add(SearchCatalogue(v)),
                    ),
                  ),
                ),

                // Section catégories (4 premières)
                if (state.categories.isNotEmpty &&
                    _searchCtrl.text.isEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Nos catégories',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () => context.go('/categories'),
                            child: const Text('Voir plus'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.categories.take(4).length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.8,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemBuilder: (context, index) {
                          final cat = state.categories[index];
                          return InkWell(
                            onTap: () => context.push(
                                '/categories/${cat.idCategorie}',
                                extra: cat.libelle),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  Icon(Icons.category_outlined,
                                      color: theme.colorScheme.secondary,
                                      size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      cat.libelle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: theme.colorScheme
                                                  .onSecondaryContainer),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],

                // Titre section produits
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      _searchCtrl.text.isEmpty
                          ? 'Nouvel arrivage'
                          : 'Résultats de recherche',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // Grille produits
                if (state.products.isEmpty &&
                    state.status == CatalogueStatus.success)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Aucun produit trouvé',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = state.products[index];
                          return ProductCard(
                            product: product,
                            onTap: () => context
                                .push('/products/${product.idProduit}'),
                            onAddToCart: () => context
                                .read<CartBloc>()
                                .add(AddToCart(product)),
                          );
                        },
                        childCount: state.products.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
