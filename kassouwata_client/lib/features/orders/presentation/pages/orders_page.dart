import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/order_entity.dart';
import '../bloc/order_bloc.dart';
import '../../../../core/widgets/connexion_requise.dart';
import '../../../../espaces/espace_menu.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<OrderBloc>().add(const LoadOrders());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BoutonMenu(), title: const Text('Mes achats')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (prev, curr) =>
            prev is! Authenticated && curr is Authenticated,
        listener: (context, state) {
          // L'utilisateur vient de se connecter → charger les commandes
          context.read<OrderBloc>().add(const LoadOrders());
        },
        builder: (context, authState) {
          // Garde : utilisateur non connecté
          if (authState is! Authenticated) {
            return const ConnexionRequise(
              titre: 'Connectez-vous pour voir vos achats',
              texte: "Retrouvez l'historique de toutes vos commandes après connexion.",
              redirectTo: '/orders',
            );
          }

          // Utilisateur connecté : afficher les commandes
          return BlocBuilder<OrderBloc, OrderState>(
            builder: (context, state) {
              if (state.status == OrderStatus2.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == OrderStatus2.failure) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(state.errorMessage ?? 'Erreur de chargement'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => context
                            .read<OrderBloc>()
                            .add(const LoadOrders()),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                );
              }
              if (state.orders.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Aucune commande',
                          style:
                              TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async =>
                    context.read<OrderBloc>().add(const LoadOrders()),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final order = state.orders[index];
                    return _OrderCard(
                      order: order,
                      onTap: () => context.push(
                        '/orders/${order.idCommande}',
                        extra: order,
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback? onTap;
  const _OrderCard({required this.order, this.onTap});

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.confirmee:
        return Colors.blue;
      case OrderStatus.livree:
        return Colors.green;
      case OrderStatus.annulee:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#${order.idCommande}',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        _statusColor(order.statut).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(order.statutLabel,
                      style: TextStyle(
                          color: _statusColor(order.statut),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(fmt.format(order.dateCommande),
                style:
                    const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            if (order.lignes.isNotEmpty) ...[
              ...order.lignes.take(3).map((l) => Text(
                    '• ${l.libelleProduit} × ${l.quantite}',
                    style: theme.textTheme.bodySmall,
                  )),
              if (order.lignes.length > 3)
                Text('  + ${order.lignes.length - 3} article(s)',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Mode de règlement
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: order.typeVente == TypeVente.prepaye
                        ? Colors.purple.withValues(alpha: 0.12)
                        : Colors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.typeVenteLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: order.typeVente == TypeVente.prepaye
                          ? Colors.purple
                          : Colors.teal,
                    ),
                  ),
                ),
                Text(
                  '${order.montantTotal.toStringAsFixed(0)} FCFA',
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary),
                ),
              ],
            ),
            // Progression des versements pour les commandes Pré-payées
            if (order.typeVente == TypeVente.prepaye &&
                order.montantTotal > 0) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payé : ${order.montantPaye.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Text(
                    order.estSolde
                        ? 'Soldé'
                        : 'Reste : ${order.montantRestant.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      fontSize: 11,
                      color: order.estSolde ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (order.montantPaye / order.montantTotal).clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    order.estSolde ? Colors.green : theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }
}
