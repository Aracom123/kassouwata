import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../paiement/data/paiement_models.dart';
import '../../domain/entities/order_entity.dart';
import '../bloc/order_bloc.dart';

/// La commande se règle-t-elle en ligne (tranches PREPAYE ou POSTPAYE en ligne) ?
bool _paiementEnLigne(OrderEntity o) =>
    o.typeVente == TypeVente.prepaye || o.modePaiement != PaymentMethod.especes;

class OrderDetailPage extends StatefulWidget {
  final OrderEntity order;
  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  @override
  void initState() {
    super.initState();
    if (_paiementEnLigne(widget.order)) {
      context
          .read<OrderBloc>()
          .add(LoadVersements(widget.order.idCommande));
    }
  }

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

  String _paymentLabel(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.carte:
        return 'Carte bancaire';
      case PaymentMethod.enLigne:
        return 'En ligne';
      default:
        return 'Espèces';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd/MM/yyyy à HH:mm');

    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state.status == OrderStatus2.cancelled) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Commande annulée avec succès'),
            backgroundColor: Colors.orange,
          ));
          Navigator.of(context).pop();
        }
        if (state.status == OrderStatus2.failure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.errorMessage ?? 'Une erreur est survenue'),
            backgroundColor: Colors.red,
          ));
        }
      },
      child: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          final cancelling = state.status == OrderStatus2.cancelling;

          final current = state.orders.cast<OrderEntity?>().firstWhere(
                    (o) => o?.idCommande == widget.order.idCommande,
                    orElse: () => null,
                  ) ??
              widget.order;

          // Versements : utilise state.versements uniquement si c'est bien
          // pour cette commande, sinon repli sur ceux embarqués dans l'entité
          final versementsDeCetteCommande =
              state.versementsCommandeId == current.idCommande;
          final versements = versementsDeCetteCommande
              ? state.versements
              : current.versements;

          // Seuls les paiements réussis (ou anciens versements manuels) comptent
          final montantPaye = versements
              .where((v) => v.estReussi)
              .fold<double>(0, (s, v) => s + v.montant);
          final paiementEnCours = versements.any((v) => v.estEnAttente);
          final double montantRestant =
              (current.montantTotal - montantPaye).clamp(0.0, current.montantTotal);
          final estSolde = montantRestant <= 0;

          return Scaffold(
            appBar: AppBar(
              title: Text('Commande #${current.idCommande}'),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(current.statut).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    current.statutLabel,
                    style: TextStyle(
                      color: _statusColor(current.statut),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Informations générales ────────────────────────────────
                _Section(
                  title: 'Informations',
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Date',
                        value: fmt.format(current.dateCommande),
                      ),
                      _InfoRow(
                        icon: Icons.payment_outlined,
                        label: 'Paiement',
                        value: _paymentLabel(current.modePaiement),
                      ),
                      _InfoRow(
                        icon: Icons.receipt_outlined,
                        label: 'Règlement',
                        value: current.typeVenteLabel,
                      ),
                      if (current.adresseLivraison != null &&
                          current.adresseLivraison!.isNotEmpty)
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Livraison',
                          value: current.adresseLivraison!,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Articles ──────────────────────────────────────────────
                _Section(
                  title: 'Articles (${current.lignes.length})',
                  child: current.lignes.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('Aucun article',
                              style: TextStyle(color: Colors.grey)),
                        )
                      : Column(
                          children: current.lignes
                              .map((l) => _LineRow(line: l, theme: theme))
                              .toList(),
                        ),
                ),
                const SizedBox(height: 16),

                // ── Total ─────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        '${current.montantTotal.toStringAsFixed(0)} FCFA',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Section paiements (pré-payé ou paiement en ligne) ────
                if (_paiementEnLigne(current)) ...[
                  _Section(
                    title: current.typeVente == TypeVente.prepaye
                        ? 'Paiements par tranche'
                        : 'Paiement',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Barre de progression
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Payé : ${montantPaye.toStringAsFixed(0)} FCFA',
                              style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                            Text(
                              estSolde
                                  ? 'Soldé'
                                  : 'Reste : ${montantRestant.toStringAsFixed(0)} FCFA',
                              style: TextStyle(
                                color:
                                    estSolde ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: current.montantTotal > 0
                                ? (montantPaye / current.montantTotal)
                                    .clamp(0.0, 1.0)
                                : 0,
                            minHeight: 8,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation(
                              estSolde ? Colors.green : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Liste des versements
                        if (state.status == OrderStatus2.versementsLoading &&
                            !versementsDeCetteCommande)
                          const Center(
                              child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(),
                          ))
                        else if (versements.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text('Aucun paiement enregistré',
                                style: TextStyle(color: Colors.grey)),
                          )
                        else
                          ...versements.map((v) => _VersementRow(
                              versement: v, theme: theme, fmt: fmt)),

                        if (paiementEnCours) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.hourglass_top,
                                  size: 16, color: Colors.orange),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Un paiement est en cours de confirmation.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade800),
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.read<OrderBloc>().add(
                                    LoadVersements(current.idCommande)),
                                child: const Text('Actualiser'),
                              ),
                            ],
                          ),
                        ],

                        // Bouton payer (écran de paiement en ligne)
                        if (!estSolde &&
                            current.statut != OrderStatus.annulee) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () =>
                                  _payer(context, current, montantRestant),
                              icon: const Icon(Icons.lock_outline, size: 18),
                              label: Text(
                                  current.typeVente == TypeVente.postpaye
                                      ? 'Payer ${montantRestant.toStringAsFixed(0)} FCFA'
                                      : current.montantParTranche != null
                                          ? 'Payer une tranche'
                                          : 'Faire un versement'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Annulation ────────────────────────────────────────────
                if (current.statut == OrderStatus.enAttente)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: cancelling
                        ? null
                        : () => _confirmCancel(context, current.idCommande),
                    icon: cancelling
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.red),
                          )
                        : const Icon(Icons.cancel_outlined),
                    label: Text(cancelling
                        ? 'Annulation...'
                        : 'Annuler la commande'),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmCancel(BuildContext context, int idCommande) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la commande'),
        content: const Text(
            'Êtes-vous sûr de vouloir annuler cette commande ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Non'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<OrderBloc>().add(CancelOrder(idCommande));
            },
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }

  /// Ouvre l'écran de paiement en ligne puis recharge les versements.
  Future<void> _payer(
      BuildContext context, OrderEntity order, double montantRestant) async {
    final orderBloc = context.read<OrderBloc>();
    final prepaye = order.typeVente == TypeVente.prepaye;
    final tranche = order.montantParTranche;

    // POSTPAYE : le reste en une fois. PREPAYE : une tranche (arrondie comme
    // côté backend), ou un montant libre plafonné au reste à payer.
    double montant = montantRestant;
    if (prepaye && tranche != null) {
      final t = tranche.ceilToDouble();
      montant = t < montantRestant ? t : montantRestant;
    }

    final issue = await context.push<IssuePaiement>(
      '/paiement',
      extra: PaiementArgs(
        typeOperation: TypeOperationPaiement.commande,
        operationId: order.idCommande,
        montant: montant,
        montantModifiable: prepaye && tranche == null,
        montantMax: montantRestant,
        titre: 'Commande #${order.idCommande}',
        sousTitre: prepaye
            ? (tranche != null ? 'Paiement d\'une tranche' : 'Versement')
            : 'Paiement de la commande',
      ),
    );

    if (issue == null) return;
    orderBloc
      ..add(LoadVersements(order.idCommande))
      ..add(const LoadOrders());
  }
}

// ─── Widgets locaux ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Text('$label : ',
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  final OrderLineEntity line;
  final ThemeData theme;
  const _LineRow({required this.line, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.libelleProduit,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  '${line.prixUnitaire.toStringAsFixed(0)} FCFA × ${line.quantite}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            '${line.subtotal.toStringAsFixed(0)} FCFA',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

// ─── Ligne versement ──────────────────────────────────────────────────────────

class _VersementRow extends StatelessWidget {
  final VersementEntity versement;
  final ThemeData theme;
  final DateFormat fmt;
  const _VersementRow(
      {required this.versement, required this.theme, required this.fmt});

  static ({IconData icon, String label}) _parseMode(String? mode) {
    return switch (mode) {
      'MOBILE_MONEY'  => (icon: Icons.phone_android_outlined, label: 'Mobile Money'),
      'STA'           => (icon: Icons.swap_horiz,             label: 'Transfert d\'argent'),
      'CARTE'         => (icon: Icons.credit_card_outlined,   label: 'Carte'),
      'CASH_LIVRAISON'=> (icon: Icons.money_outlined,         label: 'Cash'),
      _               => (icon: Icons.payments_outlined,      label: 'Inconnu'),
    };
  }

  static String _labelMoyen(String? moyen) {
    return switch (moyen) {
      'AIRTEL_MONEY' => 'Airtel Money',
      'MOOV_MONEY'   => 'Moov Money',
      'ZAMANI_CASH'  => 'Zamani Cash',
      'NITA'         => 'MyNita',
      'AMANA'        => 'Amana',
      'AMANATA'      => 'Amanata',
      'WAVE'         => 'Wave',
      'VISA'         => 'VISA',
      'MASTERCARD'   => 'Mastercard',
      _              => '',
    };
  }

  static ({IconData icon, String label, Color couleur}) _statut(
      VersementEntity v) {
    if (v.estEnAttente) {
      return (icon: Icons.hourglass_top, label: 'En attente', couleur: Colors.orange);
    }
    if (v.estEchoue) {
      return (icon: Icons.cancel_outlined, label: 'Échoué', couleur: Colors.red);
    }
    return (icon: Icons.check_circle_outline, label: 'Réussi', couleur: Colors.green);
  }

  @override
  Widget build(BuildContext context) {
    final mode  = _parseMode(versement.modePaiement);
    final moyen = _labelMoyen(versement.moyenPaiement);
    final statut = _statut(versement);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(statut.icon, size: 18, color: statut.couleur),
          const SizedBox(width: 10),
          // Infos versement (date + moyen + opérateur + statut)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date
                Text(
                  fmt.format(versement.dateTransaction),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                // Ligne "Moyen de paiement"
                _PaiementInfoRow(
                  icon: mode.icon,
                  label: 'Moyen',
                  value: mode.label,
                ),
                // Ligne "Opérateur" — uniquement si renseigné
                if (moyen.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  _PaiementInfoRow(
                    icon: Icons.hub_outlined,
                    label: 'Opérateur',
                    value: moyen,
                  ),
                ],
                if (versement.statut != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statut.couleur.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      statut.label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statut.couleur),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Montant
          Text(
            '${versement.montant.toStringAsFixed(0)} FCFA',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: versement.estEchoue
                    ? Colors.grey
                    : theme.colorScheme.primary,
                decoration:
                    versement.estEchoue ? TextDecoration.lineThrough : null),
          ),
        ],
      ),
    );
  }
}

/// Ligne compacte "label : valeur" avec icône, utilisée dans _VersementRow.
class _PaiementInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _PaiementInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          '$label : ',
          style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
