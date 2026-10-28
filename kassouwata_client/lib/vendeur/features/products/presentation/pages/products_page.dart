import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/product_bloc.dart';
import '../widgets/product_card.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  int? _idBoutique;
  bool _boutiqueCheckDone = false;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBoutiqueAndProducts();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBoutiqueAndProducts() async {
    final boutique = await getIt<AuthLocalDataSource>().getCachedBoutique();
    if (!mounted) return;
    if (boutique != null) {
      setState(() {
        _idBoutique = boutique.idBoutique;
        _boutiqueCheckDone = true;
      });
      context.read<ProductBloc>().add(LoadProducts(boutique.idBoutique));
    } else {
      setState(() => _boutiqueCheckDone = true);
    }
  }

  List<ProductEntity> _filtered(List<ProductEntity> products) {
    if (_searchQuery.isEmpty) return products;
    return products.where((p) {
      final matchLibelle = p.libelle.toLowerCase().contains(_searchQuery);
      final matchCategorie =
          p.categorie?.libelle.toLowerCase().contains(_searchQuery) ?? false;
      return matchLibelle || matchCategorie;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes produits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_idBoutique != null) {
                context.read<ProductBloc>().add(LoadProducts(_idBoutique!));
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final bloc = context.read<ProductBloc>();
          await context.push('/ma-boutique/produits/ajout');
          if (mounted && _idBoutique != null) {
            bloc.add(LoadProducts(_idBoutique!));
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: BlocConsumer<ProductBloc, ProductState>(
              listener: (context, state) {
                if (state is ProductFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                if (state is ProductOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                  if (_idBoutique != null) {
                    context.read<ProductBloc>().add(LoadProducts(_idBoutique!));
                  }
                }
              },
              builder: (context, state) {
                if (!_boutiqueCheckDone || state is ProductLoading) {
                  return _buildShimmer();
                }
                if (_idBoutique == null) {
                  return _buildNoBoutiqueState();
                }
                if (state is ProductsLoaded) {
                  final filtered = _filtered(state.products);
                  if (filtered.isEmpty) {
                    return _buildEmptyState(noResults: _searchQuery.isNotEmpty);
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      if (_idBoutique != null) {
                        context
                            .read<ProductBloc>()
                            .add(LoadProducts(_idBoutique!));
                      }
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final product = filtered[i];
                        return ProductCard(
                          product: product,
                          onTap: () async {
                            final bloc = context.read<ProductBloc>();
                            await context.push('/ma-boutique/produits/modifier', extra: product);
                            if (mounted && _idBoutique != null) {
                              bloc.add(LoadProducts(_idBoutique!));
                            }
                          },
                        );
                      },
                    ),
                  );
                }
                if (state is ProductFailure) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(state.message, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            if (_idBoutique != null) {
                              context
                                  .read<ProductBloc>()
                                  .add(LoadProducts(_idBoutique!));
                            }
                          },
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Rechercher un produit ou une catégorie…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchCtrl.clear(),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildEmptyState({bool noResults = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            noResults ? Icons.search_off : Icons.inventory_2_outlined,
            size: 72,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            noResults
                ? 'Aucun résultat pour "$_searchQuery"'
                : 'Aucun produit pour l\'instant',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          if (!noResults) ...[
            const SizedBox(height: 8),
            const Text('Appuyez sur + pour publier votre premier article'),
          ],
        ],
      ),
    );
  }

  Widget _buildNoBoutiqueState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Boutique introuvable',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Reconnectez-vous pour accéder à vos produits.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Card(
          child: SizedBox(
            height: 90,
            child: Row(
              children: [
                Container(width: 90, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          height: 14, width: double.infinity, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 100, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 60, color: Colors.white),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}