import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../domain/entities/product_entity.dart';

class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseUrl = dotenv.env['BASE_URL'] ?? '';
    final imageUrl = product.imageFilename != null
        ? '$baseUrl/images/${product.imageFilename}'
        : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                            child:
                                Icon(Icons.image_not_supported, color: Colors.grey)),
                      ),
                    )
                  : Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(
                          child: Icon(Icons.image_outlined,
                              size: 48, color: Colors.grey)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Text(
                product.libelle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${product.prix.toStringAsFixed(0)} F',
                    style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton.filled(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      icon: const Icon(Icons.add_shopping_cart),
                      onPressed: product.isAvailable ? onAddToCart : null,
                      tooltip: 'Ajouter au panier',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
