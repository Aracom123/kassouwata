import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../domain/entities/tontine_entity.dart';
import '../bloc/tontine_bloc.dart';

class TontineDetailPage extends StatefulWidget {
  final TontineEntity tontine;
  final bool isOwner;

  const TontineDetailPage({
    super.key,
    required this.tontine,
    this.isOwner = true,
  });

  @override
  State<TontineDetailPage> createState() => _TontineDetailPageState();
}

class _TontineDetailPageState extends State<TontineDetailPage>
    with SingleTickerProviderStateMixin {
  late TontineEntity _tontine;
  late TabController _tabController;
  final _dateFormat = DateFormat('dd/MM/yyyy');

  late TontineBloc _periodesBloc;
  late TontineBloc _membresBloc;
  List<DemandeAdhesionEntity> _acceptedMembers = [];
  Map<String, String> _memberDisplayNames = {};
  String? _userTelephone;

  @override
  void initState() {
    super.initState();
    _tontine = widget.tontine;
    _tabController = TabController(length: 2, vsync: this);
    _loadUser();
    _periodesBloc = getIt<TontineBloc>()
      ..add(LoadPeriodes(_tontine.idTontine));
    _membresBloc = getIt<TontineBloc>()
      ..add(LoadDemandesAdhesion(_tontine.idTontine));
    _membresBloc.stream.listen((state) {
      if (state is DemandesAdhesionLoaded && mounted) {
        setState(() {
          _acceptedMembers = state.demandes
              .where((d) => d.statut == DemandeAdhesionStatus.acceptee)
              .toList();
        });
        _fetchMemberNames(state.demandes);
      }
    });
  }

  Future<void> _loadUser() async {
    final user = await getIt<AuthLocalDataSource>().getCachedUser();
    if (mounted) setState(() => _userTelephone = user?.telephone);
  }

  Future<void> _fetchMemberNames(List<DemandeAdhesionEntity> demandes) async {
    final client = getIt<DioClient>();
    final entries = await Future.wait(
      demandes.map((d) async {
        try {
          final resp =
              await client.dio.get(ApiEndpoints.userByTelephone(d.telephone));
          final personne = resp.data?['personne'] as Map<String, dynamic>?;
          final nom = personne?['nom'] as String?;
          final prenom = personne?['prenom'] as String?;
          final parts =
              [prenom, nom].where((s) => s != null && s.isNotEmpty).join(' ');
          if (parts.isNotEmpty) return MapEntry(d.telephone, parts);
        } catch (_) {}
        return null;
      }),
    );
    if (mounted) {
      setState(() {
        for (final e in entries.whereType<MapEntry<String, String>>()) {
          _memberDisplayNames[e.key] = e.value;
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _periodesBloc.close();
    _membresBloc.close();
    super.dispose();
  }

  void _confirmDelete(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Supprimer la tontine'),
        content: Text(
            'Voulez-vous vraiment supprimer "${_tontine.libelle}" ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ctx.read<TontineBloc>().add(DeleteTontine(_tontine.idTontine));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showInviteSheet() async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: _membresBloc,
        child: _InviteSheet(tontine: _tontine),
      ),
    );
    if (sent == true && mounted) {
      _membresBloc.add(LoadDemandesAdhesion(_tontine.idTontine));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TontineBloc>(),
      child: Builder(
        builder: (ctx) => BlocListener<TontineBloc, TontineState>(
          listener: (context, state) {
            if (state is TontineOperationSuccess) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.message)));
              Navigator.of(context).pop();
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
              title:
                  Text(_tontine.libelle, overflow: TextOverflow.ellipsis),
              actions: [
                if (widget.isOwner) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Modifier',
                    onPressed: () async {
                      await context.push('/tontines/edit', extra: _tontine);
                      if (mounted) {
                        _periodesBloc
                            .add(LoadPeriodes(_tontine.idTontine));
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red),
                    tooltip: 'Supprimer',
                    onPressed: () => _confirmDelete(ctx),
                  ),
                ],
              ],
            ),
            floatingActionButton: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                if (_tabController.index == 0 && widget.isOwner) {
                  return FloatingActionButton.extended(
                    heroTag: 'fab_periode',
                    onPressed: () async {
                      await context.push('/tontines/periodes/add', extra: {
                        'tontine': _tontine,
                        'members': _acceptedMembers,
                      });
                      if (mounted) {
                        _periodesBloc
                            .add(LoadPeriodes(_tontine.idTontine));
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Nouvelle période'),
                  );
                }
                if (widget.isOwner) {
                  return FloatingActionButton.extended(
                    heroTag: 'fab_membre',
                    onPressed: _showInviteSheet,
                    icon: const Icon(Icons.person_add_outlined),
                    label: const Text('Inviter'),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            body: Column(
              children: [
                _buildInfoCard(context),
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(
                        icon: Icon(Icons.calendar_month_outlined),
                        text: 'Périodes'),
                    Tab(
                        icon: Icon(Icons.group_outlined),
                        text: 'Membres'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _PeriodesTab(
                        tontine: _tontine,
                        bloc: _periodesBloc,
                        dateFormat: _dateFormat,
                        members: _acceptedMembers,
                        isOwner: widget.isOwner,
                      ),
                      _MembresTab(
                        tontine: _tontine,
                        bloc: _membresBloc,
                        isOwner: widget.isOwner,
                        memberDisplayNames: _memberDisplayNames,
                        currentUserTelephone: _userTelephone,
                      ),
                    ],
                  ),
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
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_tontine.description != null &&
                _tontine.description!.isNotEmpty) ...[
              Text(_tontine.description!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey.shade600)),
              const Divider(height: 16),
            ],
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _chip(
                  context,
                  Icons.payments_outlined,
                  '${_tontine.montant.toStringAsFixed(0)} F/membre',
                  theme.colorScheme.primary,
                  theme.colorScheme.primaryContainer,
                ),
                if (_tontine.periodicite != null)
                  _chip(context, Icons.repeat, _tontine.periodicite!,
                      Colors.orange.shade800, Colors.orange.shade100),
                if (_tontine.tontineOwnerTelephone != null)
                  _chip(
                      context,
                      Icons.person_outline,
                      _tontine.tontineOwnerTelephone!,
                      Colors.teal.shade700,
                      Colors.teal.shade50),
                if (_tontine.dateDebut != null || _tontine.dateFin != null)
                  _chip(
                      context,
                      Icons.calendar_today_outlined,
                      _formatTontineDates(),
                      Colors.grey.shade700,
                      Colors.grey.shade200),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label,
      Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }

  String _formatTontineDates() {
    if (_tontine.dateDebut != null && _tontine.dateFin != null) {
      return '${_dateFormat.format(_tontine.dateDebut!)} → ${_dateFormat.format(_tontine.dateFin!)}';
    } else if (_tontine.dateDebut != null) {
      return 'Début ${_dateFormat.format(_tontine.dateDebut!)}';
    } else {
      return 'Fin ${_dateFormat.format(_tontine.dateFin!)}';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Onglet Périodes
// ─────────────────────────────────────────────────────────────────────────────

class _PeriodesTab extends StatelessWidget {
  final TontineEntity tontine;
  final TontineBloc bloc;
  final DateFormat dateFormat;
  final List<DemandeAdhesionEntity> members;
  final bool isOwner;

  const _PeriodesTab({
    required this.tontine,
    required this.bloc,
    required this.dateFormat,
    required this.members,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TontineBloc, TontineState>(
      bloc: bloc,
      builder: (context, state) {
        if (state is TontineLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is PeriodesLoaded) {
          if (state.periodes.isEmpty) return _buildEmpty(context);
          return RefreshIndicator(
            onRefresh: () async =>
                bloc.add(LoadPeriodes(tontine.idTontine)),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
              itemCount: state.periodes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, i) =>
                  _buildPeriodeCard(context, state.periodes[i]),
            ),
          );
        }
        if (state is TontineFailure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 8),
                Text(state.message, textAlign: TextAlign.center),
                TextButton(
                  onPressed: () => bloc.add(LoadPeriodes(tontine.idTontine)),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPeriodeCard(
      BuildContext context, PeriodeVersementEntity p) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await context.push('/tontines/periodes/detail',
              extra: {'tontine': tontine, 'periode': p, 'members': members, 'isOwner': isOwner});
          bloc.add(LoadPeriodes(tontine.idTontine));
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.calendar_today_outlined,
                    color: theme.colorScheme.secondary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.libelle,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    if (p.dateDebut != null || p.dateFin != null)
                      Text(_formatDates(p),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade600)),
                    if (p.beneficiaireTelephone != null)
                      Row(children: [
                        Icon(Icons.person_pin_outlined,
                            size: 13, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text('Bénéficiaire : ${p.beneficiaireTelephone}',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary)),
                      ]),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDates(PeriodeVersementEntity p) {
    if (p.dateDebut != null && p.dateFin != null) {
      return '${dateFormat.format(p.dateDebut!)} → ${dateFormat.format(p.dateFin!)}';
    } else if (p.dateDebut != null) {
      return 'Début : ${dateFormat.format(p.dateDebut!)}';
    }
    return 'Fin : ${dateFormat.format(p.dateFin!)}';
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month_outlined,
              size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('Aucune période créée',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey)),
          const SizedBox(height: 4),
          const Text('Appuyez sur + pour créer la première période',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Onglet Membres — demandes groupées par statut
// ─────────────────────────────────────────────────────────────────────────────

class _MembresTab extends StatelessWidget {
  final TontineEntity tontine;
  final TontineBloc bloc;
  final bool isOwner;
  final Map<String, String> memberDisplayNames;
  final String? currentUserTelephone;

  const _MembresTab({
    required this.tontine,
    required this.bloc,
    required this.isOwner,
    required this.memberDisplayNames,
    this.currentUserTelephone,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TontineBloc, TontineState>(
      bloc: bloc,
      listener: (context, state) {
        if (state is TontineOperationSuccess) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
          bloc.add(LoadDemandesAdhesion(tontine.idTontine));
        }
        if (state is TontineFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.red,
          ));
        }
      },
      builder: (context, state) {
        if (state is TontineLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is DemandesAdhesionLoaded) {
          if (state.demandes.isEmpty) return _buildEmpty(context);
          return RefreshIndicator(
            onRefresh: () async =>
                bloc.add(LoadDemandesAdhesion(tontine.idTontine)),
            child: _buildGroupedList(context, state.demandes),
          );
        }
        if (state is TontineFailure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 8),
                Text(state.message, textAlign: TextAlign.center),
                TextButton(
                  onPressed: () =>
                      bloc.add(LoadDemandesAdhesion(tontine.idTontine)),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildGroupedList(
      BuildContext context, List<DemandeAdhesionEntity> demandes) {
    final pending = demandes
        .where((d) => d.statut == DemandeAdhesionStatus.envoyee)
        .toList();
    final accepted = demandes
        .where((d) => d.statut == DemandeAdhesionStatus.acceptee)
        .toList();
    final refused = demandes
        .where((d) => d.statut == DemandeAdhesionStatus.refusee)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      children: [
        if (pending.isNotEmpty) ...[
          _sectionHeader(context, 'En attente (${pending.length})',
              Colors.orange.shade700),
          ...pending.map((d) => _buildDemandeCard(context, d)),
          const SizedBox(height: 8),
        ],
        if (accepted.isNotEmpty) ...[
          _sectionHeader(
              context, 'Membres (${accepted.length})', Colors.green.shade700),
          ...accepted.map((d) => _buildDemandeCard(context, d)),
          const SizedBox(height: 8),
        ],
        if (refused.isNotEmpty) ...[
          _sectionHeader(
              context, 'Refusés (${refused.length})', Colors.red.shade700),
          ...refused.map((d) => _buildDemandeCard(context, d)),
        ],
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildDemandeCard(
      BuildContext context, DemandeAdhesionEntity d) {
    final theme = Theme.of(context);
    final isPending = d.statut == DemandeAdhesionStatus.envoyee;
    final displayName = memberDisplayNames[d.telephone];
    final initials = displayName != null
        ? displayName.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
        : (d.telephone.isNotEmpty ? d.telephone[0] : '?');

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                initials,
                style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName ?? d.telephone,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (displayName != null)
                    Text(
                      d.telephone,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey.shade600),
                    ),
                  if (d.dateEnvoi != null)
                    Text(
                      'Invité le ${DateFormat('dd/MM/yyyy').format(d.dateEnvoi!)}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey.shade500),
                    ),
                ],
              ),
            ),
            if (isPending && d.telephone == currentUserTelephone) ...[
              IconButton(
                icon: const Icon(Icons.check_circle_outline,
                    color: Colors.green),
                tooltip: 'Accepter',
                onPressed: () => bloc.add(UpdateStatutDemande(
                  idDemandeAdhesion: d.idDemandeAdhesion,
                  statut: DemandeAdhesionStatus.acceptee,
                )),
              ),
              IconButton(
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                tooltip: 'Refuser',
                onPressed: () => bloc.add(UpdateStatutDemande(
                  idDemandeAdhesion: d.idDemandeAdhesion,
                  statut: DemandeAdhesionStatus.refusee,
                )),
              ),
            ] else ...[
              _statusBadge(d.statut),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(DemandeAdhesionStatus statut) {
    final (color, label) = switch (statut) {
      DemandeAdhesionStatus.acceptee => (Colors.green, 'Membre'),
      DemandeAdhesionStatus.refusee => (Colors.red, 'Refusé'),
      _ => (Colors.orange, 'En attente'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('Aucune invitation envoyée',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey)),
          if (isOwner) ...[
            const SizedBox(height: 4),
            const Text('Appuyez sur "Inviter" pour ajouter des membres',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet d'invitation
// ─────────────────────────────────────────────────────────────────────────────

class _InviteSheet extends StatefulWidget {
  final TontineEntity tontine;
  const _InviteSheet({required this.tontine});

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loadingContact = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickContact() async {
    setState(() => _loadingContact = true);
    try {
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permission contacts refusée')));
        }
        return;
      }
      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) return;
      final full = await FlutterContacts.getContact(contact.id);
      final phones = full?.phones ?? [];
      if (phones.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ce contact n\'a pas de numéro')));
        }
        return;
      }
      String? chosen;
      if (phones.length == 1) {
        chosen = phones.first.number;
      } else if (mounted) {
        chosen = await showDialog<String>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: Text('Choisir un numéro\n${full?.displayName ?? ''}',
                style: const TextStyle(fontSize: 14)),
            children: phones
                .map((p) => SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, p.number),
                      child: Text(p.number),
                    ))
                .toList(),
          ),
        );
      }
      if (chosen != null) {
        setState(() => _phoneCtrl.text = chosen!.replaceAll(' ', ''));
      }
    } finally {
      if (mounted) setState(() => _loadingContact = false);
    }
  }

  String _buildInviteMessage() {
    return 'Bonjour ! Je vous invite à rejoindre ma tontine '
        '"${widget.tontine.libelle}" sur Kassouwata. '
        'Cotisation : ${widget.tontine.montant.toStringAsFixed(0)} F par membre'
        '${widget.tontine.periodicite != null ? ' (${widget.tontine.periodicite})' : ''}. '
        'Téléchargez l\'application et créez un compte pour rejoindre !';
  }

  Future<void> _sendAndRecord(
      Future<void> Function(String phone, String message) launcher) async {
    if (!_formKey.currentState!.validate()) return;
    final phone = _phoneCtrl.text.trim();
    final message = _buildInviteMessage();
    await launcher(phone, message);
    if (mounted) {
      context.read<TontineBloc>().add(CreateDemandeAdhesion(
            idTontine: widget.tontine.idTontine,
            telephone: phone,
          ));
    }
  }

  Future<void> _launchWhatsApp() async {
    await _sendAndRecord((phone, message) async {
      final uri =
          Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    });
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _launchSms() async {
    await _sendAndRecord((phone, message) async {
      final uri =
          Uri.parse('sms:$phone?body=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    });
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _launchFacebook() async {
    final message = _buildInviteMessage();
    final uri = Uri.parse(
        'https://www.facebook.com/sharer/sharer.php?quote=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (_formKey.currentState!.validate() && mounted) {
      context.read<TontineBloc>().add(CreateDemandeAdhesion(
            idTontine: widget.tontine.idTontine,
            telephone: _phoneCtrl.text.trim(),
          ));
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<TontineBloc, TontineState>(
      listener: (context, state) {
        if (state is TontineFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.red,
          ));
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Inviter un membre',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Tontine : ${widget.tontine.libelle}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Numéro de téléphone',
                        hintText: '+22790000000',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Tooltip(
                    message: 'Choisir dans les contacts',
                    child: InkWell(
                      onTap: _loadingContact ? null : _pickContact,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 58,
                        width: 58,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _loadingContact
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2))
                            : Icon(Icons.contacts_outlined,
                                color: theme.colorScheme.primary, size: 26),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Envoyer via',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: Colors.grey.shade600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _inviteButton(context,
                        label: 'WhatsApp',
                        icon: Icons.chat_outlined,
                        color: const Color(0xFF25D366),
                        onTap: _launchWhatsApp),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _inviteButton(context,
                        label: 'SMS',
                        icon: Icons.sms_outlined,
                        color: Colors.blueGrey,
                        onTap: _launchSms),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _inviteButton(context,
                        label: 'Facebook',
                        icon: Icons.facebook,
                        color: const Color(0xFF1877F2),
                        onTap: _launchFacebook),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inviteButton(BuildContext context,
      {required String label,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }
}
