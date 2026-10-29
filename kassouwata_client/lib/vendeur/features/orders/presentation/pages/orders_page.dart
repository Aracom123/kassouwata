import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/di/injection.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../domain/entities/order_entity.dart';
import '../bloc/order_bloc.dart';
import '../../../../../espaces/espace_menu.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  int? _idBoutique;
  bool _boutiqueCheckDone = false;

  @override
  void initState() {
    super.initState();
    _loadBoutiqueAndOrders();
  }

  Future<void> _loadBoutiqueAndOrders() async {
    final boutique = await getIt<AuthLocalDataSource>().getCachedBoutique();
    if (!mounted) return;
    if (boutique != null) {
      setState(() {
        _idBoutique = boutique.idBoutique;
        _boutiqueCheckDone = true;
      });
      context.read<OrderBloc>().add(LoadOrders(boutique.idBoutique));
    } else {
      setState(() => _boutiqueCheckDone = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BoutonMenu(),
        title: const Text('Commandes reçues'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_idBoutique != null) {
                context.read<OrderBloc>().add(LoadOrders(_idBoutique!));
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          if (!_boutiqueCheckDone || state is OrderLoading) {
            return _buildShimmer();
          }
          if (_idBoutique == null) {
            return _buildNoBoutique();
          }
          if (state is OrderFailure) {
            return _buildError(state.message);
          }
          if (state is OrdersLoaded) {
            if (state.orders.isEmpty) return _buildEmpty();
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<OrderBloc>().add(LoadOrders(_idBoutique!)),
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: state.orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _OrderCard(
                  order: state.orders[i],
                  idBoutique: _idBoutique!,
                  onTap: () => context.push(
                    '/vendeur/commandes/detail',
                    extra: {
                      'order': state.orders[i],
                      'idBoutique': _idBoutique!,
                    },
                  ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              if (_idBoutique != null) {
                context.read<OrderBloc>().add(LoadOrders(_idBoutique!));
              }
            },
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Aucune commande pour l\'instant',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Les commandes de vos clients apparaîtront ici.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoBoutique() {
    return const Center(
      child: Text('Boutique introuvable. Reconnectez-vous.'),
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
            height: 88,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 120, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 200, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 80, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderEntity order;
  final int idBoutique;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.idBoutique,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final montant = order.montantPourBoutique(idBoutique);
    final nbLignes = order.lignesPourBoutique(idBoutique).length;
    final statut = _OrderStatusHelper.fromString(order.statut);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Indicateur de statut
              Container(
                width: 4,
                height: 56,
                decoration: BoxDecoration(
                  color: statut.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Commande #${order.idCommande}',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        _StatusBadge(statut: statut),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.client != null
                          ? 'Client : ${order.client!.displayName}'
                          : 'Client inconnu',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.grey600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 13, color: AppColors.grey400),
                        const SizedBox(width: 4),
                        Text(
                          '$nbLignes article${nbLignes > 1 ? 's' : ''}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.grey600),
                        ),
                        const Spacer(),
                        Text(
                          '${NumberFormat('#,###', 'fr_FR').format(montant)} F',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    if (order.dateCommande != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd/MM/yyyy à HH:mm').format(
                            order.dateCommande!.toLocal()),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: AppColors.grey400),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.grey400),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _OrderStatus statut;
  const _StatusBadge({required this.statut});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: statut.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statut.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: statut.color,
        ),
      ),
    );
  }
}

enum _OrderStatus { enAttente, confirmee, enCours, livree, annulee, autre }

extension _OrderStatusHelper on _OrderStatus {
  static _OrderStatus fromString(String s) => switch (s.toUpperCase()) {
        'EN_ATTENTE' => _OrderStatus.enAttente,
        'CONFIRMEE' => _OrderStatus.confirmee,
        'EN_COURS' || 'EN_LIVRAISON' => _OrderStatus.enCours,
        'LIVREE' || 'LIVREE' => _OrderStatus.livree,
        'ANNULEE' => _OrderStatus.annulee,
        _ => _OrderStatus.autre,
      };

  Color get color => switch (this) {
        _OrderStatus.enAttente => AppColors.statusPending,
        _OrderStatus.confirmee => AppColors.statusConfirmed,
        _OrderStatus.enCours => AppColors.statusShipping,
        _OrderStatus.livree => AppColors.statusDelivered,
        _OrderStatus.annulee => AppColors.statusCancelled,
        _OrderStatus.autre => AppColors.grey400,
      };

  String get label => switch (this) {
        _OrderStatus.enAttente => 'En attente',
        _OrderStatus.confirmee => 'Confirmée',
        _OrderStatus.enCours => 'En livraison',
        _OrderStatus.livree => 'Livrée',
        _OrderStatus.annulee => 'Annulée',
        _OrderStatus.autre => 'Inconnu',
      };
}
