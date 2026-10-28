import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/get_products_usecase.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  ProductEntity? _product;
  bool _loading = true;
  String? _error;

  /// Index de l'image actuellement affichée dans la galerie.
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    final usecase = getIt<GetProductByIdUseCase>();
    final result = await usecase(widget.productId);
    result.fold(
      (f) => setState(() {
        _error = f.message;
        _loading = false;
      }),
      (p) => setState(() {
        _product = p;
        _loading = false;
      }),
    );
  }

  /// Ouvre la visionneuse plein écran avec zoom à partir de [initialIndex].
  void _openImageViewer(List<String> imageUrls, int initialIndex) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _ImageViewerPage(
        imageUrls: imageUrls,
        initialIndex: initialIndex,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error!)),
      );
    }

    final product = _product!;
    final baseUrl = dotenv.env['BASE_URL'] ?? '';
    final imageUrls = product.allImageFilenames
        .map((f) => '$baseUrl/images/$f')
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(product.libelle)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Galerie d'images ───────────────────────────────────────
            _buildImageGallery(imageUrls, theme),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Chips catégorie & boutique ──────────────────────
                  _buildChips(context, product, theme),
                  const SizedBox(height: 12),

                  // ─── Nom du produit ──────────────────────────────────
                  Text(
                    product.libelle,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // ─── Prix ────────────────────────────────────────────
                  Text(
                    '${product.prix.toStringAsFixed(0)} FCFA',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ─── Stock ───────────────────────────────────────────
                  Row(children: [
                    Icon(
                      product.isAvailable
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      size: 16,
                      color: product.isAvailable ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      product.isAvailable
                          ? 'En stock${product.quantiteStock != null ? ' (${product.quantiteStock})' : ''}'
                          : 'Rupture de stock',
                      style: TextStyle(
                        color: product.isAvailable ? Colors.green : Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  ]),

                  // ─── Paiement prépayé / tranches ─────────────────────
                  if (product.nombreTranches != null &&
                      product.nombreTranches! >= 2) ...[
                    const SizedBox(height: 16),
                    _buildTranchesCard(product, theme),
                  ],

                  // ─── Description ─────────────────────────────────────
                  if (product.description != null &&
                      product.description!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Description',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description!,
                      style:
                          theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                    ),
                  ],


                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: product.isAvailable
                ? () {
                    context.read<CartBloc>().add(AddToCart(product));
                    final messenger = ScaffoldMessenger.of(context);
                    final router = GoRouter.of(context);
                    messenger.hideCurrentSnackBar();
                    final barre = messenger.showSnackBar(SnackBar(
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                      content: Row(
                        children: [
                          Expanded(
                            child: Text('${product.libelle} ajouté au panier'),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.white),
                            onPressed: () {
                              messenger.hideCurrentSnackBar();
                              router.push('/cart');
                            },
                            child: const Text('Voir le panier'),
                          ),
                        ],
                      ),
                    ));
                    // Fermeture garantie après 3 s : les versions récentes de
                    // Flutter laissent affichée une barre qui contient un bouton.
                    var fermee = false;
                    barre.closed.then((_) => fermee = true);
                    Future.delayed(const Duration(seconds: 3), () {
                      if (!fermee) barre.close();
                    });
                  }
                : null,
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Ajouter au panier'),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GALERIE D'IMAGES
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildImageGallery(List<String> imageUrls, ThemeData theme) {
    if (imageUrls.isEmpty) {
      return Container(
        height: 280,
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Center(
          child: Icon(Icons.image_outlined, size: 80, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        // Carrousel principal
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            itemCount: imageUrls.length,
            onPageChanged: (i) => setState(() => _currentImageIndex = i),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _openImageViewer(imageUrls, index),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrls[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: Icon(Icons.image_not_supported,
                              size: 64, color: Colors.grey),
                        ),
                      ),
                    ),
                    // Icône zoom
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.zoom_in,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Indicateurs de page (dots)
        if (imageUrls.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(imageUrls.length, (i) {
              final isActive = i == _currentImageIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),

          // Miniatures cliquables
          SizedBox(
            height: 68,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              scrollDirection: Axis.horizontal,
              itemCount: imageUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final isSelected = i == _currentImageIndex;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(i,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        imageUrls[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported,
                              size: 20, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CHIPS CATÉGORIE & BOUTIQUE
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildChips(
      BuildContext context, ProductEntity product, ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        // Chip catégorie → naviguer vers les produits de la catégorie
        if (product.categorie != null)
          ActionChip(
            avatar: const Icon(Icons.category_outlined, size: 16),
            label: Text(product.categorie!.libelle),
            labelStyle: theme.textTheme.labelMedium,
            onPressed: () => context.push(
              '/categories/${product.categorie!.idCategorie}',
              extra: product.categorie!.libelle,
            ),
          ),

        // Chip boutique → naviguer vers la page boutique
        if (product.idBoutique != null && product.boutiqueName != null)
          ActionChip(
            avatar: const Icon(Icons.storefront_outlined, size: 16),
            label: Text(product.boutiqueName!),
            labelStyle: theme.textTheme.labelMedium,
            backgroundColor:
                theme.colorScheme.secondaryContainer.withOpacity(0.6),
            onPressed: () => context.push(
              '/boutiques/${product.idBoutique}',
              extra: product.boutiqueName,
            ),
          ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CARTE PAIEMENT EN TRANCHES
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildTranchesCard(ProductEntity product, ThemeData theme) {
    final n = product.nombreTranches!;
    final montantParTranche = product.prix / n;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.payments_outlined,
                color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Paiement prépayé disponible',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Text(
            'Ce produit peut être réglé en $n tranches.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          // Visualisation des tranches
          Row(
            children: List.generate(n, (i) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < n - 1 ? 4 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.25),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'T${i + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${montantParTranche.toStringAsFixed(0)} F',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Soit ${montantParTranche.toStringAsFixed(0)} FCFA / tranche',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }

}

// ────────────────────────────────────────────────────────────────────────────
// VISIONNEUSE PLEIN ÉCRAN AVEC ZOOM
// ────────────────────────────────────────────────────────────────────────────

class _ImageViewerPage extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _ImageViewerPage({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<_ImageViewerPage> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 5.0,
                child: Center(
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.image_not_supported,
                          color: Colors.grey, size: 64),
                    ),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // Indicateurs de page
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.imageUrls.length, (i) {
                  final isActive = i == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
