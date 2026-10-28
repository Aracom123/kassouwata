import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/app_colors.dart';
import '../bloc/dashboard_bloc.dart';
import '../widgets/stat_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          BlocBuilder<DashboardBloc, DashboardState>(
            buildWhen: (_, s) => s is DashboardLoaded || s is DashboardLoading,
            builder: (context, state) => IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: () =>
                  context.read<DashboardBloc>().add(const LoadDashboard()),
            ),
          ),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<DashboardBloc>().add(const LoadDashboard()),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WelcomeBanner(state: state),
                  const SizedBox(height: 24),
                  const Text(
                    'Vue d\'ensemble',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _StatsGrid(state: state),
                  if (state is DashboardFailure) ...[
                    const SizedBox(height: 16),
                    _ErrorBanner(message: state.message),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Accès rapide',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _QuickActions(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Welcome banner ────────────────────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  final DashboardState state;
  const _WelcomeBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final boutiqueName =
        state is DashboardLoaded ? (state as DashboardLoaded).boutiqueName : null;
    final userName =
        state is DashboardLoaded ? (state as DashboardLoaded).userName : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(Icons.store, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName != null && userName.isNotEmpty
                      ? 'Bonjour, $userName !'
                      : 'Bonjour !',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  boutiqueName ?? 'Mon espace vendeur',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats grid ────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final DashboardState state;
  const _StatsGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state is DashboardLoading || state is DashboardInitial) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: const [
          StatCardShimmer(),
          StatCardShimmer(),
          StatCardShimmer(),
          StatCardShimmer(),
        ],
      );
    }

    final d = state is DashboardLoaded ? state as DashboardLoaded : null;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        StatCard(
          title: 'Commandes',
          value: d != null ? '${d.nbCommandes}' : '—',
          subtitle: d != null
              ? '${d.nbCommandesEnAttente} en attente'
              : 'En attente',
          icon: Icons.shopping_bag_outlined,
          color: AppColors.statusPending,
        ),
        StatCard(
          title: 'Produits',
          value: d != null ? '${d.nbProduits}' : '—',
          subtitle: d != null ? '${d.nbProduitsActifs} actifs' : 'En vente',
          icon: Icons.inventory_2_outlined,
          color: AppColors.primary,
        ),
        StatCard(
          title: 'Tontines',
          value: d != null ? '${d.nbTontines}' : '—',
          subtitle: d != null
              ? '${d.nbTontinesCreees} créées · ${d.nbTontinesRejointes} rejointes'
              : 'Créées et rejointes',
          icon: Icons.savings_outlined,
          color: AppColors.secondary,
        ),
        StatCard(
          title: 'Chiffre d\'affaires',
          value: d != null
              ? NumberFormat('#,###', 'fr_FR').format(d.revenuTotal)
              : '—',
          subtitle: 'Commandes livrées',
          icon: Icons.trending_up,
          color: AppColors.statusDelivered,
        ),
      ],
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick actions ─────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  // push:true → context.push (page au-dessus du shell, retour possible)
  // push:false → context.go  (onglet du shell, remplace la pile)
  final _actions = const [
    _QuickAction('Ajouter un produit', Icons.add_box_outlined, '/ma-boutique/produits/ajout', push: true),
    _QuickAction('Mes produits', Icons.inventory_2_outlined, '/ma-boutique/produits', push: true),
    _QuickAction('Commandes reçues', Icons.receipt_long_outlined, '/ma-boutique/commandes', push: true),
    _QuickAction('Paramètres boutique', Icons.store_outlined, '/ma-boutique/parametres', push: true),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: _actions.length,
      itemBuilder: (context, index) {
        final action = _actions[index];
        return InkWell(
          onTap: () => action.push
              ? context.push(action.route)
              : context.go(action.route),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Row(
              children: [
                Icon(action.icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    action.label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final String route;
  final bool push;
  const _QuickAction(this.label, this.icon, this.route, {this.push = false});
}
