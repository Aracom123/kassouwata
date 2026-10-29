import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../paiement/data/paiement_models.dart';
import '../../domain/entities/demande_entity.dart';
import '../bloc/tontine_client_bloc.dart';
import '../widgets/adashe_produit_widgets.dart';

class TontineDetailPage extends StatefulWidget {
  final int tontineId;
  final TontineEntity tontine;

  const TontineDetailPage({
    super.key,
    required this.tontineId,
    required this.tontine,
  });

  @override
  State<TontineDetailPage> createState() => _TontineDetailPageState();
}

class _TontineDetailPageState extends State<TontineDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));

    context.read<TontineClientBloc>()
      ..add(LoadPeriodes(widget.tontineId))
      ..add(LoadTontineDemandes(widget.tontineId))
      ..add(const LoadAllVersements())
      ..add(const LoadUsers());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAddPeriodeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<TontineClientBloc>(),
        child: _AddPeriodeSheet(tontineId: widget.tontineId),
      ),
    );
  }

  void _openInviteSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<TontineClientBloc>(),
        child: _InviteMembreSheet(tontineId: widget.tontineId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd/MM/yyyy');
    final fmtAmount = NumberFormat('#,##0', 'fr_FR');
    final t = widget.tontine;

    final authState = context.read<AuthBloc>().state;
    final currentIdUser =
        authState is Authenticated ? authState.user.idUser : '';
    final isOwner = widget.tontine.ownerIdUser == currentIdUser;

    return BlocListener<TontineClientBloc, TontineClientState>(
      listenWhen: (prev, curr) =>
          prev.addPeriodeStatus != curr.addPeriodeStatus ||
          prev.versementStatus != curr.versementStatus ||
          prev.inviteMembreStatus != curr.inviteMembreStatus,
      listener: (context, state) {
        if (state.addPeriodeStatus == TontineLoadStatus.success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Période ajoutée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state.addPeriodeStatus == TontineLoadStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Erreur lors de l\'ajout'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
        if (state.inviteMembreStatus == TontineLoadStatus.success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invitation envoyée avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state.inviteMembreStatus == TontineLoadStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(state.errorMessage ?? 'Erreur lors de l\'invitation'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.libelle),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.calendar_month_outlined), text: 'Périodes'),
              Tab(icon: Icon(Icons.people_outline), text: 'Membres'),
            ],
          ),
        ),
        // Adashé Produit : périodes générées automatiquement à l'accord du vendeur
        floatingActionButton: _tabController.index == 0 && !t.estProduit
            ? FloatingActionButton.extended(
                onPressed: _openAddPeriodeSheet,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une période'),
              )
            : (isOwner
                ? FloatingActionButton.extended(
                    onPressed: _openInviteSheet,
                    icon: const Icon(Icons.person_add_outlined),
                    label: const Text('Inviter un membre'),
                  )
                : null),
        body: Column(
          children: [
            // ── Header info ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              color: theme.colorScheme.surfaceContainerLow,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Wrap(
                spacing: 20,
                runSpacing: 4,
                children: [
                  _InfoChip(
                    icon: Icons.payments_outlined,
                    label:
                        '${fmtAmount.format(t.montant)} FCFA'
                        '${t.periodicite != null ? ' · ${t.periodicite}' : ''}',
                  ),
                  if (t.dateDebut != null || t.dateFin != null)
                    _InfoChip(
                      icon: Icons.date_range_outlined,
                      label: [
                        if (t.dateDebut != null) fmt.format(t.dateDebut!),
                        if (t.dateFin != null) fmt.format(t.dateFin!),
                      ].join(' → '),
                    ),
                  if (t.description != null && t.description!.isNotEmpty)
                    _InfoChip(
                      icon: Icons.notes,
                      label: t.description!,
                    ),
                ],
              ),
            ),
            // ── Adashé Produit : produit, statut, progression ───────────────
            if (t.estProduit) AdasheProduitStatutCard(idTontine: t.idTontine),
            // ── Tabs ─────────────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _PeriodesTab(
                      tontineId: widget.tontineId,
                      tontine: widget.tontine),
                  _MembresTab(
                      tontineId: widget.tontineId,
                      ownerIdUser: widget.tontine.ownerIdUser),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Tab Périodes
// ──────────────────────────────────────────────────────────────────────────────

class _PeriodesTab extends StatelessWidget {
  final int tontineId;
  final TontineEntity tontine;
  const _PeriodesTab({required this.tontineId, required this.tontine});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TontineClientBloc, TontineClientState>(
      buildWhen: (prev, curr) =>
          prev.periodesStatus != curr.periodesStatus ||
          prev.periodes != curr.periodes ||
          prev.allVersementsStatus != curr.allVersementsStatus ||
          prev.allVersements != curr.allVersements ||
          prev.versementStatus != curr.versementStatus ||
          prev.usersStatus != curr.usersStatus ||
          prev.users != curr.users,
      builder: (context, state) {
        if (state.periodesStatus == TontineLoadStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.periodesStatus == TontineLoadStatus.failure) {
          return _ErrorView(
            message: state.errorMessage,
            onRetry: () => context
                .read<TontineClientBloc>()
                .add(LoadPeriodes(tontineId)),
          );
        }

        final periodes =
            state.periodes.where((p) => p.idTontine == tontineId).toList();

        if (periodes.isEmpty) {
          return const _EmptyView(
            icon: Icons.calendar_today_outlined,
            message: 'Aucune période définie',
            hint: 'Appuyez sur + pour ajouter une période de versement',
          );
        }

        final authState = context.read<AuthBloc>().state;
        final userTel =
            authState is Authenticated ? authState.user.telephone : '';
        final userIdUser =
            authState is Authenticated ? authState.user.idUser : '';
        final nameMap = {
          for (final u in state.users) u.telephone: u.displayName
        };
        final isVersing =
            state.versementStatus == TontineLoadStatus.loading;

        return RefreshIndicator(
          onRefresh: () async {
            context.read<TontineClientBloc>()
              ..add(LoadPeriodes(tontineId))
              ..add(const LoadAllVersements())
              ..add(const LoadUsers());
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: periodes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final periode = periodes[index];
              final versementsPeriode = state.allVersements
                  .where((v) =>
                      v.idTontinePeriodeVersement ==
                      periode.idTontinePeriodeVersement)
                  .toList();
              final hasPaid = versementsPeriode
                  .any((v) => v.membreTelephone == userTel);
              return _PeriodeCard(
                periode: periode,
                versements: versementsPeriode,
                hasPaid: hasPaid,
                isVersing: isVersing,
                tontineMontant: tontine.montant,
                userTelephone: userTel,
                userIdUser: userIdUser,
                nameMap: nameMap,
              );
            },
          ),
        );
      },
    );
  }
}

class _PeriodeCard extends StatelessWidget {
  final PeriodeVersementEntity periode;
  final List<TontineVersementEntity> versements;
  final bool hasPaid;
  final bool isVersing;
  final double tontineMontant;
  final String userTelephone;
  final String userIdUser;
  final Map<String, String> nameMap;

  const _PeriodeCard({
    required this.periode,
    required this.versements,
    required this.hasPaid,
    required this.isVersing,
    required this.tontineMontant,
    required this.userTelephone,
    required this.userIdUser,
    required this.nameMap,
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
        montant: tontineMontant,
        titre: 'Cotisation Adashé',
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
          // ── En-tête ──────────────────────────────────────────────────────
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
                if (periode.dateDebut != null || periode.dateFin != null) ...[
                  const SizedBox(height: 6),
                  Row(children: [
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
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ]),
                ],
                if (periode.beneficiaireTelephone != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.person_outline,
                        size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Bénéficiaire : ${nameMap[periode.beneficiaireTelephone!] ?? periode.beneficiaireTelephone}',
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ]),
                ],
              ],
            ),
          ),

          // ── Liste des versements ──────────────────────────────────────────
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
      color: isCurrentUser ? Colors.green.withValues(alpha: 0.05) : null,
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
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
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
// Tab Membres
// ──────────────────────────────────────────────────────────────────────────────

class _MembresTab extends StatelessWidget {
  final int tontineId;
  final String? ownerIdUser;
  const _MembresTab({required this.tontineId, this.ownerIdUser});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final currentUserTel =
        authState is Authenticated ? authState.user.telephone : '';
    final currentIdUser =
        authState is Authenticated ? authState.user.idUser : '';
    // Vrai si l'utilisateur connecté est le créateur de la tontine
    final isOwner = ownerIdUser != null && ownerIdUser == currentIdUser;

    return BlocBuilder<TontineClientBloc, TontineClientState>(
      buildWhen: (prev, curr) =>
          prev.tontineDemandesStatus != curr.tontineDemandesStatus ||
          prev.tontineDemandes != curr.tontineDemandes,
      builder: (context, state) {
        if (state.tontineDemandesStatus == TontineLoadStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.tontineDemandesStatus == TontineLoadStatus.failure) {
          return _ErrorView(
            message: state.errorMessage,
            onRetry: () => context
                .read<TontineClientBloc>()
                .add(LoadTontineDemandes(tontineId)),
          );
        }

        final pending = state.tontineDemandes
            .where((d) => d.statut == DemandeStatus.envoyee)
            .toList();
        final members = state.tontineDemandes
            .where((d) => d.statut == DemandeStatus.acceptee)
            .toList();
        final refused = state.tontineDemandes
            .where((d) => d.statut == DemandeStatus.refusee)
            .toList();

        if (state.tontineDemandes.isEmpty) {
          return const _EmptyView(
            icon: Icons.people_outline,
            message: 'Aucune demande d\'adhésion',
            hint: 'Les demandes pour rejoindre cet Adashé apparaîtront ici',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => context
              .read<TontineClientBloc>()
              .add(LoadTontineDemandes(tontineId)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pending.isNotEmpty) ...[
                _SectionHeader(
                    title: 'En attente',
                    count: pending.length,
                    color: Colors.orange),
                const SizedBox(height: 8),
                ...pending.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _DemandeCard(
                        demande: d,
                        currentUserTelephone: currentUserTel,
                        isOwner: isOwner,
                      ),
                    )),
                const SizedBox(height: 12),
              ],
              if (members.isNotEmpty) ...[
                _SectionHeader(
                    title: 'Membres',
                    count: members.length,
                    color: Colors.green),
                const SizedBox(height: 8),
                ...members.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _DemandeCard(
                        demande: d,
                        currentUserTelephone: currentUserTel,
                        isOwner: isOwner,
                      ),
                    )),
                const SizedBox(height: 12),
              ],
              if (refused.isNotEmpty) ...[
                _SectionHeader(
                    title: 'Refusés',
                    count: refused.length,
                    color: Colors.red),
                const SizedBox(height: 8),
                ...refused.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _DemandeCard(
                        demande: d,
                        currentUserTelephone: currentUserTel,
                        isOwner: isOwner,
                      ),
                    )),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DemandeCard extends StatelessWidget {
  final DemandeAdhesionEntity demande;
  final String currentUserTelephone;
  /// Vrai si l'utilisateur connecté est le créateur de la tontine.
  /// Dans ce cas les boutons Accepter/Refuser sont masqués.
  final bool isOwner;

  const _DemandeCard({
    required this.demande,
    required this.currentUserTelephone,
    required this.isOwner,
  });

  Color _statusColor(DemandeStatus s) => switch (s) {
        DemandeStatus.acceptee => Colors.green,
        DemandeStatus.refusee => Colors.red,
        _ => Colors.orange,
      };

  String _statusLabel(DemandeStatus s) => switch (s) {
        DemandeStatus.acceptee => 'Membre',
        DemandeStatus.refusee => 'Refusé',
        _ => 'En attente',
      };

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final theme = Theme.of(context);

    final isCurrentUser = demande.telephone == currentUserTelephone;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      _statusColor(demande.statut).withValues(alpha: 0.15),
                  child: Icon(
                    isCurrentUser ? Icons.person : Icons.person_outline,
                    color: _statusColor(demande.statut),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCurrentUser ? 'Vous' : demande.telephone,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isCurrentUser
                              ? theme.colorScheme.primary
                              : null,
                        ),
                      ),
                      if (demande.dateEnvoi != null)
                        Text(
                          'Invité le ${fmt.format(demande.dateEnvoi!)}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(demande.statut)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel(demande.statut),
                    style: TextStyle(
                      color: _statusColor(demande.statut),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            // Boutons masqués uniquement pour le créateur de la tontine
            if (demande.statut == DemandeStatus.envoyee && !isOwner) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          context.read<TontineClientBloc>().add(
                                RespondToInvitation(
                                  idDemande: demande.idDemandeAdhesion,
                                  response: DemandeStatus.refusee,
                                ),
                              ),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 8)),
                      child: const Text('Refuser'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          context.read<TontineClientBloc>().add(
                                RespondToInvitation(
                                  idDemande: demande.idDemandeAdhesion,
                                  response: DemandeStatus.acceptee,
                                ),
                              ),
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8)),
                      child: const Text('Accepter'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Formulaire invitation d'un membre
// ──────────────────────────────────────────────────────────────────────────────

class _InviteMembreSheet extends StatefulWidget {
  final int tontineId;
  const _InviteMembreSheet({required this.tontineId});

  @override
  State<_InviteMembreSheet> createState() => _InviteMembreSheetState();
}

class _InviteMembreSheetState extends State<_InviteMembreSheet> {
  final _formKey = GlobalKey<FormState>();
  final _telephoneCtrl = TextEditingController();

  @override
  void dispose() {
    _telephoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<TontineClientBloc>().add(InviteMembre(
          idTontine: widget.tontineId,
          telephone: _telephoneCtrl.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Inviter un membre',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Entrez le numéro de téléphone de la personne à inviter',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _telephoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Numéro de téléphone *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: 'Ex: 77000000',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Champ requis';
                if (v.trim().length < 8) {
                  return 'Le numéro doit contenir au moins 8 chiffres';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            BlocBuilder<TontineClientBloc, TontineClientState>(
              buildWhen: (prev, curr) =>
                  prev.inviteMembreStatus != curr.inviteMembreStatus,
              builder: (context, state) {
                final loading =
                    state.inviteMembreStatus == TontineLoadStatus.loading;
                return SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: loading ? null : _submit,
                    icon: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_outlined, size: 18),
                    label: Text(
                        loading ? 'Envoi en cours…' : 'Envoyer l\'invitation'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Formulaire ajout de période
// ──────────────────────────────────────────────────────────────────────────────

class _AddPeriodeSheet extends StatefulWidget {
  final int tontineId;
  const _AddPeriodeSheet({required this.tontineId});

  @override
  State<_AddPeriodeSheet> createState() => _AddPeriodeSheetState();
}

class _AddPeriodeSheetState extends State<_AddPeriodeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _libelleCtrl = TextEditingController();

  DateTime? _dateDebut;
  DateTime? _dateFin;
  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void dispose() {
    _libelleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isDebut}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isDebut ? _dateDebut : _dateFin) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() => isDebut ? _dateDebut = picked : _dateFin = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<TontineClientBloc>().add(AddPeriode(
          libelle: _libelleCtrl.text.trim(),
          idTontine: widget.tontineId,
          dateDebut: _dateDebut,
          dateFin: _dateFin,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ajouter une période',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _libelleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Libellé de la période *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_outline),
                  hintText: 'Ex: Janvier 2025',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _DatePickerField(
                      label: 'Date de début',
                      date: _dateDebut,
                      fmt: _dateFmt,
                      onTap: () => _pickDate(isDebut: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DatePickerField(
                      label: 'Date de fin',
                      date: _dateFin,
                      fmt: _dateFmt,
                      onTap: () => _pickDate(isDebut: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              BlocBuilder<TontineClientBloc, TontineClientState>(
                buildWhen: (prev, curr) =>
                    prev.addPeriodeStatus != curr.addPeriodeStatus,
                builder: (context, state) {
                  final loading =
                      state.addPeriodeStatus == TontineLoadStatus.loading;
                  return SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: loading ? null : _submit,
                      child: loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Ajouter la période'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Widgets utilitaires partagés
// ──────────────────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold, color: Colors.grey[700]),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final DateFormat fmt;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.fmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          date != null ? fmt.format(date!) : '——',
          style: TextStyle(color: date != null ? null : Colors.grey),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  final String hint;

  const _EmptyView({
    required this.icon,
    required this.message,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(message,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey)),
            const SizedBox(height: 8),
            Text(hint,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const _ErrorView({this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message ?? 'Une erreur est survenue'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
