import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/order_entity.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../bloc/order_bloc.dart';

class OrderDetailPage extends StatefulWidget {
  final OrderEntity order;
  final int idBoutique;

  const OrderDetailPage({
    super.key,
    required this.order,
    required this.idBoutique,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late OrderEntity _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  void _updateStatut(String newStatut) {
    context.read<OrderBloc>().add(
          UpdateOrderStatut(_order.idCommande, newStatut),
        );
  }

  @override
  Widget build(BuildContext context) {
    // Onglet Règlements : commandes prépayées, payées en ligne,
    // ou ayant déjà au moins un règlement.
    final moyen = _order.moyenPaiement?.toUpperCase();
    final isPrePaye = _order.versements.isNotEmpty ||
        _order.typeVente?.toUpperCase() == 'PREPAYE' ||
        (moyen != null && moyen != 'CASH_LIVRAISON' && moyen != 'ESPECES');
    final tabCount = isPrePaye ? 2 : 1;

    return DefaultTabController(
      length: tabCount,
      child: BlocConsumer<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderStatusUpdated) {
            setState(() => _order = state.order);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Statut mis à jour : ${_statusOf(state.order.statut).label}'),
                backgroundColor: Colors.green,
              ),
            );
          }
          if (state is OrderFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        buildWhen: (_, current) =>
            current is OrderStatusUpdating ||
            current is OrderStatusUpdated ||
            current is OrderFailure ||
            current is OrderInitial,
        builder: (context, state) {
          final isUpdating = state is OrderStatusUpdating;
          final lignes = _order.lignesPourBoutique(widget.idBoutique);
          final montant = _order.montantPourBoutique(widget.idBoutique);
          final statut = _statusOf(_order.statut);
          final actions = _nextActions(_order.statut);

          return Scaffold(
            backgroundColor: AppColors.background,
            bottomNavigationBar: actions.isEmpty
                ? null
                : _ActionBar(
                    actions: actions,
                    isLoading: isUpdating,
                    onTap: _updateStatut,
                  ),
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  title: Text('Commande #${_order.idCommande}'),
                  pinned: true,
                  floating: true,
                  forceElevated: innerBoxIsScrolled,
                  bottom: TabBar(
                    tabs: [
                      const Tab(
                        icon: Icon(Icons.inventory_2_outlined),
                        text: 'Produits',
                      ),
                      if (isPrePaye)
                        Tab(
                          icon: const Icon(Icons.receipt_outlined),
                          text: 'Règlements (${_order.versements.length})',
                        ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: _InfoCard(order: _order, statut: statut),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  // ── Onglet Produits ──────────────────────────────────
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      if (lignes.isEmpty)
                        const _EmptyTab(
                          icon: Icons.inventory_2_outlined,
                          message:
                              'Aucun produit de votre boutique\ndans cette commande.',
                        )
                      else ...[
                        ...lignes.map((l) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _OrderItemTile(item: l),
                            )),
                        const SizedBox(height: 8),
                        _TotalCard(montant: montant, nbLignes: lignes.length),
                      ],
                    ],
                  ),

                  // ── Onglet Règlements ────────────────────────────────
                  if (isPrePaye)
                    ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      children: [
                        if (_order.versements.isEmpty)
                          const _EmptyTab(
                            icon: Icons.receipt_long_outlined,
                            message: 'Aucun règlement enregistré.',
                          )
                        else ...[
                          ..._order.versements.map((v) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _ReglementTile(reglement: v),
                              )),
                          const SizedBox(height: 8),
                          _TotalReglements(versements: _order.versements),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── transitions ──────────────────────────────────────────────────────────────

class _OrderAction {
  final String statut;
  final String label;
  final IconData icon;
  final bool isDanger;
  const _OrderAction({
    required this.statut,
    required this.label,
    required this.icon,
    this.isDanger = false,
  });
}

List<_OrderAction> _nextActions(String statut) => switch (statut.toUpperCase()) {
      'EN_ATTENTE' => [
          const _OrderAction(
            statut: 'CONFIRMEE',
            label: 'Confirmer',
            icon: Icons.check_circle_outline,
          ),
          const _OrderAction(
            statut: 'ANNULEE',
            label: 'Annuler',
            icon: Icons.cancel_outlined,
            isDanger: true,
          ),
        ],
      'CONFIRMEE' => [
          const _OrderAction(
            statut: 'EN_LIVRAISON',
            label: 'Mettre en livraison',
            icon: Icons.local_shipping_outlined,
          ),
          const _OrderAction(
            statut: 'ANNULEE',
            label: 'Annuler',
            icon: Icons.cancel_outlined,
            isDanger: true,
          ),
        ],
      'EN_LIVRAISON' => [
          const _OrderAction(
            statut: 'LIVREE',
            label: 'Marquer comme livrée',
            icon: Icons.done_all,
          ),
        ],
      _ => [],
    };

// ── _ActionBar ────────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final List<_OrderAction> actions;
  final bool isLoading;
  final void Function(String statut) onTap;

  const _ActionBar({
    required this.actions,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  height: 40,
                  child: CircularProgressIndicator(),
                ),
              )
            : Row(
                children: actions.map((a) {
                  final isFirst = actions.first == a;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: isFirst ? 0 : 8),
                      child: a.isDanger
                          ? OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.statusCancelled,
                                side: const BorderSide(
                                    color: AppColors.statusCancelled),
                              ),
                              icon: Icon(a.icon, size: 18),
                              label: Text(a.label),
                              onPressed: () => _confirm(context, a),
                            )
                          : FilledButton.icon(
                              icon: Icon(a.icon, size: 18),
                              label: Text(a.label),
                              onPressed: () => onTap(a.statut),
                            ),
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }

  void _confirm(BuildContext context, _OrderAction action) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer l\'annulation'),
        content: const Text(
            'Cette action est irréversible. Annuler la commande ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: AppColors.statusCancelled),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) onTap(action.statut);
    });
  }
}

// ── helpers ──────────────────────────────────────────────────────────────────

String _labelMoyenPaiement(String s) => switch (s.toUpperCase()) {
      'CASH_LIVRAISON' || 'ESPECES' => 'Espèces à la livraison',
      'EN_LIGNE' => 'Paiement en ligne',
      'MOBILE_MONEY' => 'Mobile Money',
      'STA' => 'Transfert d\'argent',
      'CARTE' => 'Carte bancaire',
      'AIRTEL_MONEY' => 'Airtel Money',
      'MOOV_MONEY' => 'Moov Money',
      'ZAMANI_CASH' => 'Zamani Cash',
      'NITA' => 'MyNita',
      'AMANA' => 'Amana',
      'AMANATA' => 'Amanata',
      'VISA' => 'Visa',
      'MASTERCARD' => 'Mastercard',
      _ => s,
    };

_StatusData _statusOf(String s) => switch (s.toUpperCase()) {
      'EN_ATTENTE' => _StatusData('En attente', AppColors.statusPending),
      'CONFIRMEE' => _StatusData('Confirmée', AppColors.statusConfirmed),
      'EN_COURS' || 'EN_LIVRAISON' =>
        _StatusData('En livraison', AppColors.statusShipping),
      'LIVREE' => _StatusData('Livrée', AppColors.statusDelivered),
      'ANNULEE' => _StatusData('Annulée', AppColors.statusCancelled),
      _ => _StatusData(s, AppColors.grey400),
    };

class _StatusData {
  final String label;
  final Color color;
  const _StatusData(this.label, this.color);
}

// ── widgets ───────────────────────────────────────────────────────────────────

class _EmptyTab extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyTab({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.grey400),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final OrderEntity order;
  final _StatusData statut;

  const _InfoCard({required this.order, required this.statut});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _InfoRow(
              icon: Icons.circle,
              iconColor: statut.color,
              label: 'Statut',
              value: statut.label,
              valueColor: statut.color,
              bold: true,
            ),
            if (order.dateCommande != null) ...[
              const Divider(height: 20),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                value: DateFormat('dd/MM/yyyy à HH:mm')
                    .format(order.dateCommande!.toLocal()),
              ),
            ],
            if (order.client != null) ...[
              const Divider(height: 20),
              _InfoRow(
                icon: Icons.person_outline,
                label: 'Client',
                value: order.client!.displayName,
              ),
              if (order.client!.telephone != null) ...[
                const Divider(height: 20),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Téléphone',
                  value: order.client!.telephone!,
                ),
              ],
            ],
            if (order.adresseLivraison != null &&
                order.adresseLivraison!.isNotEmpty) ...[
              const Divider(height: 20),
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Adresse',
                value: order.adresseLivraison!,
              ),
            ],
            if (order.moyenPaiement != null &&
                order.moyenPaiement!.isNotEmpty) ...[
              const Divider(height: 20),
              _InfoRow(
                icon: Icons.payment_outlined,
                label: 'Règlement',
                value: _labelMoyenPaiement(order.moyenPaiement!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _InfoRow({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor ?? AppColors.grey400),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.grey600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  final OrderItemEntity item;

  const _OrderItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = item.produit;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            _ProductImage(product: product),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product?.libelle ?? 'Produit #${item.idProduitCommande}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product?.categorie != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      product!.categorie!.libelle,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: AppColors.grey400),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'x${item.quantite}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${NumberFormat('#,###', 'fr_FR').format(item.prixUnitaire)} F/u',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${NumberFormat('#,###', 'fr_FR').format(item.sousTotal)} F',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.grey900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final ProductEntity? product;
  const _ProductImage({required this.product});

  @override
  Widget build(BuildContext context) {
    if (product?.imagePrincipale == null ||
        product!.imagePrincipale!.isEmpty) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(Icons.image_outlined, size: 28, color: Colors.grey),
        ),
      );
    }

    final url =
        ApiEndpoints.imageUrl(AppConfig.baseUrl, product!.imagePrincipale!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        placeholder: (_, __) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(color: Colors.white, width: 64, height: 64),
        ),
        errorWidget: (_, __, ___) => Container(
          width: 64,
          height: 64,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
        ),
      ),
    );
  }
}

class _ReglementTile extends StatelessWidget {
  final ReglementEntity reglement;
  const _ReglementTile({required this.reglement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = reglement.moyenPaiement != null
        ? _labelMoyenPaiement(reglement.moyenPaiement!)
        : _labelMoyenPaiement(reglement.modePaiement ?? '');
    final (statutLabel, statutColor, statutIcon) = reglement.estEnAttente
        ? ('En attente', Colors.orange.shade700, Icons.hourglass_top)
        : reglement.estEchoue
            ? ('Échoué', Colors.red.shade700, Icons.cancel_outlined)
            : ('Réussi', Colors.green.shade700, Icons.check_circle_outline);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statutColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(statutIcon, size: 18, color: statutColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (reglement.dateTransaction != null)
                    Text(
                      DateFormat('dd/MM/yyyy à HH:mm')
                          .format(reglement.dateTransaction!.toLocal()),
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: AppColors.grey400),
                    ),
                  if (reglement.statut != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statutColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(statutLabel,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statutColor)),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              '${NumberFormat('#,###', 'fr_FR').format(reglement.montant)} F',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: reglement.estEchoue
                    ? AppColors.grey400
                    : AppColors.primary,
                decoration:
                    reglement.estEchoue ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double montant;
  final int nbLignes;

  const _TotalCard({required this.montant, required this.nbLignes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: AppColors.primary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.2), width: 1),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total votre boutique',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.grey600),
                ),
                Text(
                  '$nbLignes article${nbLignes > 1 ? 's' : ''}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.grey400),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '${NumberFormat('#,###', 'fr_FR').format(montant)} F',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalReglements extends StatelessWidget {
  final List<ReglementEntity> versements;
  const _TotalReglements({required this.versements});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Seuls les règlements réussis (ou anciens règlements manuels) comptent
    final reussis = versements.where((v) => v.estReussi).toList();
    final total = reussis.fold(0.0, (sum, v) => sum + v.montant);
    final enAttente = versements.where((v) => v.estEnAttente).length;
    return Card(
      color: AppColors.primary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.2), width: 1),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total réglé',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.grey600),
                ),
                Text(
                  '${reussis.length} versement${reussis.length > 1 ? 's' : ''}'
                  '${enAttente > 0 ? ' · $enAttente en attente' : ''}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.grey400),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '${NumberFormat('#,###', 'fr_FR').format(total)} F',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
