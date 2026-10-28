import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/product_entity.dart';

class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.libelle,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.categorie != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.label_outline,
                              size: 13, color: theme.colorScheme.secondary),
                          const SizedBox(width: 4),
                          Text(
                            product.categorie!.libelle,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${product.prixUnitaire.toStringAsFixed(0)} F',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: product.statut
                                ? Colors.green.shade100
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Qté: ${product.quantite}',
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                    if (!product.statut) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Indisponible',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (product.imagePrincipale == null || product.imagePrincipale!.isEmpty) {
      return Container(
        width: 90,
        height: 90,
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.image_outlined, size: 36, color: Colors.grey),
        ),
      );
    }

    final url = ApiEndpoints.imageUrl(AppConfig.baseUrl, product.imagePrincipale!);
    return CachedNetworkImage(
      imageUrl: url,
      width: 90,
      height: 90,
      fit: BoxFit.cover,
      placeholder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(color: Colors.white, width: 90, height: 90),
      ),
      errorWidget: (_, __, ___) => Container(
        width: 90,
        height: 90,
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.broken_image_outlined, size: 36, color: Colors.grey),
        ),
      ),
    );
  }
}