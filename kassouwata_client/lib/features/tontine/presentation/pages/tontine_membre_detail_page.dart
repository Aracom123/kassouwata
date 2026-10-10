import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../paiement/data/paiement_models.dart';
import '../../domain/entities/demande_entity.dart';
import '../bloc/tontine_client_bloc.dart';

class TontineMembreDetailPage extends StatefulWidget {
  final int tontineId;
  final String? tontineLibelle;

  const TontineMembreDetailPage({
    super.key,
    required this.tontineId,
    this.tontineLibelle,
  });

  @override
  State<TontineMembreDetailPage> createState() =>
      _TontineMembreDetailPageState();
}

class _TontineMembreDetailPageState extends State<TontineMembreDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<TontineClientBloc>()
      ..add(LoadCurrentTontine(widget.tontineId))
      ..add(LoadPeriodes(widget.tontineId))
      ..add(LoadTontineDemandes(widget.tontineId))
      ..add(const LoadAllVersements())
      ..add(const LoadUsers());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TontineClientBloc, TontineClientState>(
      listenWhen: (prev, curr) =>
          prev.versementStatus != curr.versementStatus,
      listener: (context, state) {
        if (state.versementStatus == TontineLoadStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cotisation versée avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state.versementStatus == TontineLoadStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Erreur lors du versement'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<TontineClientBloc, TontineClientState>(
            buildWhen: (p, c) => p.currentTontine != c.currentTontine,
            builder: (_, state) => Text(
              state.currentTontine?.libelle ??
                  widget.tontineLibelle ??
                  'Tontine',
            ),
          ),
        ),
        body: BlocBuilder<TontineClientBloc, TontineClientState>(
          buildWhen: (prev, curr) =>
              prev.currentTontineStatus != curr.currentTontineStatus ||
              prev.periodesStatus != curr.periodesStatus ||
              prev.tontineDemandesStatus != curr.tontineDemandesStatus ||
              prev.allVersementsStatus != curr.allVersementsStatus ||
              prev.usersStatus != curr.usersStatus ||
              prev.currentTontine != curr.currentTontine ||
              prev.periodes != curr.periodes ||
              prev.tontineDemandes != curr.tontineDemandes ||
              prev.allVersements != curr.allVersements ||
              prev.users != curr.users ||
              prev.versementStatus != curr.versementStatus,
          builder: (context, state) {
            final isLoading = state.currentTontineStatus ==
                    TontineLoadStatus.loading ||
                state.periodesStatus == TontineLoadStatus.loading ||
                state.tontineDemandesStatus == TontineLoadStatus.loading ||
                state.allVersementsStatus == TontineLoadStatus.loading;

            if (isLoading && state.currentTontine == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final authState = context.read<AuthBloc>().state;
            final userTel = authState is Authenticated
                ? authState.user.telephone
                : '';
            final userIdUser = authState is Authenticated
                ? authState.user.idUser
                : '';

            final nameMap = {
              for (final u in state.users) u.telephone: u.displayName
            };

            final tontine = state.currentTontine;
            final periodes = state.periodes
                .where((p) => p.idTontine == widget.tontineId)
                .toList();
            final membres = state.tontineDemandes
                .where((d) => d.statut == DemandeStatus.acceptee)
                .toList();

            return RefreshIndicator(
              onRefresh: () async {
                context.read<TontineClientBloc>()
                  ..add(LoadCurrentTontine(widget.tontineId))
                  ..add(LoadPeriodes(widget.tontineId))
                  ..add(LoadTontineDemandes(widget.tontineId))
                  ..add(const LoadAllVersements())
                  ..add(const LoadUsers());
              },
              child: CustomScrollView(
                slivers: [
                  // ── Info tontine ────────────────────────────────────────────
                  if (tontine != null)
                    SliverToBoxAdapter(
                      child: _TontineInfoCard(tontine: tontine),
                    ),

                  // ── Membres ─────────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'Membres',
                      count: membres.length,
                    ),
                  ),
                  if (membres.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(
                          'Aucun membre pour le moment',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: membres
                              .map((m) => _MembreChip(
                                    label: nameMap[m.telephone] ?? m.telephone,
                                  ))
                              .toList(),
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // ── Périodes ─────────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'Périodes de versement',
                      count: periodes.length,
                    ),
                  ),
                  if (periodes.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(
                          'Aucune période définie',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList.separated(
                        itemCount: periodes.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final periode = periodes[i];
                          final versementsPeriode = state.allVersements
                              .where((v) =>
                                  v.idTontinePeriodeVersement ==
                                  periode.idTontinePeriodeVersement)
                              .toList();
                          final hasPaid = versementsPeriode.any(
                              (v) => v.membreTelephone == userTel);
                          final isVersing =
                              state.versementStatus ==
                                  TontineLoadStatus.loading;

                          return _PeriodeDetailCard(
                            periode: periode,
                            versements: versementsPeriode,
                            hasPaid: hasPaid,
                            isVersing: isVersing,
                            tontineMontant: tontine?.montant,
                            userTelephone: userTel,
                            userIdUser: userIdUser,
                            nameMap: nameMap,
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Info card
// ──────────────────────────────────────────────────────────────────────────────

class _TontineInfoCard extends StatelessWidget {
  final TontineEntity tontine;
  const _TontineInfoCard({required this.tontine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd/MM/yyyy');
    final fmtAmount = NumberFormat('#,##0', 'fr_FR');

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.savings,
                  color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tontine.libelle,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _InfoItem(
                icon: Icons.payments_outlined,
                label:
                    '${fmtAmount.format(tontine.montant)} FCFA'
                    '${tontine.periodicite != null ? ' / ${tontine.periodicite}' : ''}',
              ),
              if (tontine.dateDebut != null || tontine.dateFin != null)
                _InfoItem(
                  icon: Icons.date_range_outlined,
                  label: [
                    if (tontine.dateDebut != null)
                      fmt.format(tontine.dateDebut!),
                    if (tontine.dateFin != null) fmt.format(tontine.dateFin!),
                  ].join(' → '),
                ),
            ],
          ),
          if (tontine.description != null &&
              tontine.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              tontine.description!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 13, color: Colors.grey[700])),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Période card avec versements intégrés
// ──────────────────────────────────────────────────────────────────────────────

class _PeriodeDetailCard extends StatelessWidget {
  final PeriodeVersementEntity periode;
  final List<TontineVersementEntity> versements;
  final bool hasPaid;
  final bool isVersing;
  final double? tontineMontant;
  final String userTelephone;
  final String userIdUser;
  final Map<String, String> nameMap;

  const _PeriodeDetailCard({
    required this.periode,
    required this.versements,
    required this.hasPaid,
    required this.isVersing,
    required this.userTelephone,
    required this.userIdUser,
    required this.nameMap,
    this.tontineMontant,
  });

  /// Ouvre l'écran de paiement en ligne (Mobile Money, transfert, carte)
  /// pour la cotisation de cette période, puis recharge les versements.
  Future<void> _showPaySheet(BuildContext context) async {
    final bloc = context.read<TontineClientBloc>();
    final issue = await context.push<IssuePaiement>(
      '/paiement',
      extra: PaiementArgs(
        typeOperation: TypeOperationPaiement.tontine,
        operationId: periode.idTontine!,
        periodeVersementId: periode.idTontinePeriodeVersement,
        montant: tontineMontant ?? 0,
        montantModifiable: tontineMontant == null,
        titre: 'Cotisation tontine',
        sousTitre: periode.libelle ??
            'Période #${periode.idTontinePeriodeVersement}',
      ),
    );
    if (issue != null) bloc.add(const LoadAllVersements());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd/MM/yyyy');
    final fmtAmount = NumberFormat('#,##0', 'fr_FR');

    return Card(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête période ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.calendar_month,
                          color: theme.colorScheme.onSecondaryContainer,
                          size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        periode.libelle ??
                            'Période #${periode.idTontinePeriodeVersement}',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (hasPaid)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                size: 12, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              'Versé',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (periode.dateDebut != null ||
                    periode.dateFin != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.date_range_outlined,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        [
                          if (periode.dateDebut != null)
                            fmt.format(periode.dateDebut!),
                          if (periode.dateFin != null)
                            fmt.format(periode.dateFin!),
                        ].join(' → '),
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
                if (periode.beneficiaireTelephone != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Bénéficiaire : ${nameMap[periode.beneficiaireTelephone!] ?? periode.beneficiaireTelephone}',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Versements effectués ──────────────────────────────────────────
          if (versements.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Text(
                'Versements effectués (${versements.length})',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ),
            ...versements.map((v) => _VersementRow(
                  versement: v,
                  fmtAmount: fmtAmount,
                  fmt: fmt,
                  isCurrentUser: v.membreTelephone == userTelephone,
                  displayName: v.membreTelephone != null
                      ? nameMap[v.membreTelephone!]
                      : null,
                )),
          ],

          // ── Bouton versement ──────────────────────────────────────────────
          if (!hasPaid) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      isVersing ? null : () => _showPaySheet(context),
                  icon: isVersing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send, size: 16),
                  label: Text(isVersing
                      ? 'Versement en cours…'
                      : 'Verser ma cotisation'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VersementRow extends StatelessWidget {
  final TontineVersementEntity versement;
  final NumberFormat fmtAmount;
  final DateFormat fmt;
  final bool isCurrentUser;
  final String? displayName;

  const _VersementRow({
    required this.versement,
    required this.fmtAmount,
    required this.fmt,
    required this.isCurrentUser,
    this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: isCurrentUser
          ? Colors.green.withValues(alpha: 0.05)
          : null,
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: isCurrentUser
                ? Colors.green.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.12),
            child: Icon(
              isCurrentUser ? Icons.person : Icons.person_outline,
              size: 14,
              color: isCurrentUser ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrentUser
                      ? 'Vous'
                      : (displayName ?? versement.membreTelephone ?? '—'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: isCurrentUser
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isCurrentUser ? Colors.green[700] : null,
                  ),
                ),
                if (versement.dateVersement != null)
                  Text(
                    fmt.format(versement.dateVersement!),
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11),
                  ),
              ],
            ),
          ),
          if (versement.montant != null)
            Text(
              '${fmtAmount.format(versement.montant!)} FCFA',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Widgets utilitaires
// ──────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MembreChip extends StatelessWidget {
  final String label;
  const _MembreChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const CircleAvatar(
        child: Icon(Icons.person, size: 14),
      ),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.only(right: 8),
    );
  }
}
