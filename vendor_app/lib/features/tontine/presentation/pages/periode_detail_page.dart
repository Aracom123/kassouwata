import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../paiement/data/paiement_models.dart';
import '../../domain/entities/tontine_entity.dart';
import '../bloc/tontine_bloc.dart';

class PeriodeDetailPage extends StatefulWidget {
  final TontineEntity tontine;
  final PeriodeVersementEntity periode;
  final List<DemandeAdhesionEntity> members;
  final bool isOwner;

  const PeriodeDetailPage({
    super.key,
    required this.tontine,
    required this.periode,
    this.members = const [],
    this.isOwner = true,
  });

  @override
  State<PeriodeDetailPage> createState() => _PeriodeDetailPageState();
}

class _PeriodeDetailPageState extends State<PeriodeDetailPage> {
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  void _confirmDelete(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Supprimer la période'),
        content: Text(
            'Voulez-vous vraiment supprimer "${widget.periode.libelle}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ctx.read<TontineBloc>().add(DeletePeriode(
                    widget.periode.idTontinePeriodeVersement,
                  ));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  /// Ouvre l'écran de paiement en ligne (Mobile Money, transfert, carte)
  /// pour la cotisation de cette période, puis recharge les versements.
  Future<void> _cotiser(BuildContext ctx) async {
    final bloc = ctx.read<TontineBloc>();
    final messenger = ScaffoldMessenger.of(ctx);
    final issue = await ctx.push<IssuePaiement>(
      '/paiement',
      extra: PaiementArgs(
        typeOperation: TypeOperationPaiement.tontine,
        operationId: widget.tontine.idTontine,
        periodeVersementId: widget.periode.idTontinePeriodeVersement,
        montant: widget.tontine.montant,
        titre: 'Cotisation — ${widget.tontine.libelle}',
        sousTitre: widget.periode.libelle,
      ),
    );
    if (issue == null) return;
    bloc.add(LoadVersements(widget.periode.idTontinePeriodeVersement));
    if (issue.reussi) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Cotisation payée avec succès !')));
    } else if (issue.statut == StatutPaiement.enAttente) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Paiement en cours de confirmation…')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TontineBloc>()
        ..add(LoadVersements(widget.periode.idTontinePeriodeVersement)),
      child: Builder(
        builder: (ctx) => BlocListener<TontineBloc, TontineState>(
          listener: (context, state) {
            if (state is TontineOperationSuccess) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.message)));
              Navigator.of(context).pop();
            }
            if (state is VersementCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cotisation enregistrée !')));
              ctx.read<TontineBloc>().add(LoadVersements(
                    widget.periode.idTontinePeriodeVersement,
                  ));
            }
            if (state is TontineFailure) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ));
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(widget.periode.libelle,
                  overflow: TextOverflow.ellipsis),
              actions: [
                if (widget.isOwner) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Modifier',
                    onPressed: () async {
                      await context.push('/tontines/periodes/add', extra: {
                        'tontine': widget.tontine,
                        'periode': widget.periode,
                        'members': widget.members,
                      });
                      if (ctx.mounted) {
                        ctx.read<TontineBloc>().add(LoadVersements(
                              widget.periode.idTontinePeriodeVersement,
                            ));
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Supprimer',
                    onPressed: () => _confirmDelete(ctx),
                  ),
                ],
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _cotiser(ctx),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Cotiser'),
            ),
            body: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildInfoCard(context)),
                SliverToBoxAdapter(child: _buildVersementsHeader(context)),
                BlocBuilder<TontineBloc, TontineState>(
                  builder: (context, state) {
                    if (state is TontineLoading || state is VersementCreated) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      );
                    }
                    if (state is VersementsLoaded) {
                      if (state.versements.isEmpty) {
                        return SliverToBoxAdapter(
                            child: _buildEmptyVersements(context));
                      }
                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => _buildVersementTile(
                                context, state.versements[i]),
                            childCount: state.versements.length,
                          ),
                        ),
                      );
                    }
                    if (state is TontineFailure) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(state.message,
                                      style: const TextStyle(
                                          color: Colors.red))),
                              TextButton(
                                onPressed: () => ctx
                                    .read<TontineBloc>()
                                    .add(LoadVersements(widget
                                        .periode
                                        .idTontinePeriodeVersement)),
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.periode;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p.dateDebut != null || p.dateFin != null)
              _infoRow(context, Icons.calendar_today_outlined, 'Période',
                  _formatDates(p)),
            if (p.beneficiaireTelephone != null) ...[
              const SizedBox(height: 10),
              _infoRow(context, Icons.person_pin_outlined, 'Bénéficiaire',
                  p.beneficiaireTelephone!,
                  valueColor: theme.colorScheme.primary, bold: true),
            ],
            const Divider(height: 20),
            _infoRow(context, Icons.payments_outlined, 'Cotisation/membre',
                '${widget.tontine.montant.toStringAsFixed(0)} F'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label,
      String value,
      {Color? valueColor, bool bold = false}) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text('$label : ',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: Colors.grey.shade600)),
        Expanded(
          child: Text(value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: valueColor,
                fontWeight: bold ? FontWeight.bold : null,
              )),
        ),
      ],
    );
  }

  Widget _buildVersementsHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 18),
          const SizedBox(width: 8),
          Text('Versements des membres',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildVersementTile(
      BuildContext context, TontineVersementEntity v) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,###', 'fr_FR');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    _initials(v.displayName),
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.displayName,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      if (v.displayName != v.displayPhone)
                        Text(v.displayPhone,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Text(
                  '${fmt.format(v.montant)} F',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (v.typePaiement != null || v.dateVersement != null) ...[
              const Divider(height: 14),
              Row(
                children: [
                  if (v.typePaiement != null) ...[
                    _paymentBadge(context, v),
                    const SizedBox(width: 8),
                  ],
                  if (v.dateVersement != null)
                    Text(
                      _dateTimeFormat.format(v.dateVersement!),
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: Colors.grey.shade500),
                    ),
                ],
              ),
            ],
            if (v.typePaiement == TontineTypePaiement.mobileMoney &&
                v.numeroCompte != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.phone_android_outlined,
                    size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(v.numeroCompte!,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: Colors.grey.shade600)),
              ]),
            ],
            if (v.typePaiement == TontineTypePaiement.cartePaiement) ...[
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.credit_card_outlined,
                    size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  [
                    if (v.nomPorteur != null) v.nomPorteur!,
                    if (v.numeroCarte != null)
                      '•••• ${_quatreDerniers(v.numeroCarte!)}',
                  ].join('  '),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: Colors.grey.shade600),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _paymentBadge(BuildContext context, TontineVersementEntity v) {
    final label = v.fournisseur?.label ?? v.typePaiement!.label;
    final isMobile = v.typePaiement == TontineTypePaiement.mobileMoney;
    final color = isMobile ? Colors.green.shade700 : Colors.blue.shade700;
    final bg = isMobile ? Colors.green.shade50 : Colors.blue.shade50;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMobile ? Icons.phone_android_outlined : Icons.credit_card_outlined,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  /// Le backend renvoie la carte masquée (« **** **** **** 1234 ») :
  /// on n'affiche que les 4 derniers chiffres.
  String _quatreDerniers(String carte) {
    final chiffres = carte.replaceAll(RegExp(r'[^0-9]'), '');
    return chiffres.length <= 4 ? chiffres : chiffres.substring(chiffres.length - 4);
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Widget _buildEmptyVersements(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('Aucun versement enregistré',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey)),
            const SizedBox(height: 4),
            const Text('Appuyez sur "Cotiser" pour envoyer votre cotisation',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  String _formatDates(PeriodeVersementEntity p) {
    if (p.dateDebut != null && p.dateFin != null) {
      return '${_dateFormat.format(p.dateDebut!)} → ${_dateFormat.format(p.dateFin!)}';
    } else if (p.dateDebut != null) {
      return 'Début : ${_dateFormat.format(p.dateDebut!)}';
    } else if (p.dateFin != null) {
      return 'Fin : ${_dateFormat.format(p.dateFin!)}';
    }
    return '';
  }
}
