import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/demande_entity.dart';
import '../bloc/tontine_client_bloc.dart';

class TontineListPage extends StatefulWidget {
  const TontineListPage({super.key});

  @override
  State<TontineListPage> createState() => _TontineListPageState();
}

class _TontineListPageState extends State<TontineListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));

    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<TontineClientBloc>()
        ..add(LoadMyTontines(authState.user.idUser))
        ..add(LoadMyInvitations(authState.user.telephone));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<TontineClientBloc>(),
        child: const _CreateTontineSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      buildWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
      listenWhen: (prev, curr) =>
          prev is! Authenticated && curr is Authenticated,
      listener: (context, state) {
        // L'utilisateur vient de se connecter → charger les tontines
        if (state is Authenticated) {
          context.read<TontineClientBloc>()
            ..add(LoadMyTontines(state.user.idUser))
            ..add(LoadMyInvitations(state.user.telephone));
        }
      },
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return Scaffold(
            appBar: AppBar(title: const Text('Tontines')),
            body: const _UnauthenticatedView(),
          );
        }

        return BlocListener<TontineClientBloc, TontineClientState>(
          listenWhen: (prev, curr) =>
              prev.createTontineStatus != curr.createTontineStatus,
          listener: (context, state) {
            if (state.createTontineStatus == TontineLoadStatus.success) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tontine créée avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state.createTontineStatus == TontineLoadStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text(state.errorMessage ?? 'Erreur lors de la création'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Tontines'),
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Mes tontines'),
                  Tab(text: 'Invitations'),
                ],
              ),
            ),
            floatingActionButton: _tabController.index == 0
                ? FloatingActionButton.extended(
                    onPressed: _openCreateSheet,
                    icon: const Icon(Icons.add),
                    label: const Text('Nouvelle tontine'),
                  )
                : null,
            body: TabBarView(
              controller: _tabController,
              children: const [
                _MyTontinesTab(),
                _InvitationsTab(),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Tab 1 : Mes tontines
// ──────────────────────────────────────────────────────────────────────────────

class _MyTontinesTab extends StatelessWidget {
  const _MyTontinesTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TontineClientBloc, TontineClientState>(
      buildWhen: (prev, curr) =>
          prev.myTontinesStatus != curr.myTontinesStatus ||
          prev.myTontines != curr.myTontines,
      builder: (context, state) {
        if (state.myTontinesStatus == TontineLoadStatus.initial ||
            state.myTontinesStatus == TontineLoadStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.myTontinesStatus == TontineLoadStatus.failure) {
          return _ErrorView(
            message: state.errorMessage,
            onRetry: () {
              final authState = context.read<AuthBloc>().state;
              if (authState is Authenticated) {
                context
                    .read<TontineClientBloc>()
                    .add(LoadMyTontines(authState.user.idUser));
              }
            },
          );
        }

        if (state.myTontines.isEmpty) {
          return const _EmptyView(
            icon: Icons.savings_outlined,
            message: 'Aucune tontine créée',
            hint: 'Appuyez sur + pour créer votre première tontine',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            final authState = context.read<AuthBloc>().state;
            if (authState is Authenticated) {
              context
                  .read<TontineClientBloc>()
                  .add(LoadMyTontines(authState.user.idUser));
            }
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: state.myTontines.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final tontine = state.myTontines[index];
              return _TontineCard(tontine: tontine);
            },
          ),
        );
      },
    );
  }
}

class _TontineCard extends StatelessWidget {
  final TontineEntity tontine;
  const _TontineCard({required this.tontine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd/MM/yyyy');
    final fmtAmount = NumberFormat('#,##0', 'fr_FR');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.savings,
                      color: theme.colorScheme.onPrimaryContainer, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tontine.libelle,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.payments_outlined,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${fmtAmount.format(tontine.montant)} FCFA'
                  '${tontine.periodicite != null ? ' · ${tontine.periodicite}' : ''}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            if (tontine.dateDebut != null || tontine.dateFin != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.date_range_outlined,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    [
                      if (tontine.dateDebut != null)
                        fmt.format(tontine.dateDebut!),
                      if (tontine.dateFin != null)
                        fmt.format(tontine.dateFin!),
                    ].join(' → '),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ],
            if (tontine.description != null &&
                tontine.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                tontine.description!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push(
                  '/tontines/${tontine.idTontine}',
                  extra: tontine,
                ),
                icon: const Icon(Icons.manage_search, size: 16),
                label: const Text('Consulter les détails'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Tab 2 : Invitations
// ──────────────────────────────────────────────────────────────────────────────

class _InvitationsTab extends StatelessWidget {
  const _InvitationsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TontineClientBloc, TontineClientState>(
      buildWhen: (prev, curr) =>
          prev.invitationsStatus != curr.invitationsStatus ||
          prev.invitations != curr.invitations,
      builder: (context, state) {
        if (state.invitationsStatus == TontineLoadStatus.initial ||
            state.invitationsStatus == TontineLoadStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.invitationsStatus == TontineLoadStatus.failure) {
          return _ErrorView(
            message: state.errorMessage,
            onRetry: () {
              final authState = context.read<AuthBloc>().state;
              if (authState is Authenticated) {
                context
                    .read<TontineClientBloc>()
                    .add(LoadMyInvitations(authState.user.telephone));
              }
            },
          );
        }

        final pending = state.invitations
            .where((d) => d.statut == DemandeStatus.envoyee)
            .toList();
        final accepted = state.invitations
            .where((d) => d.statut == DemandeStatus.acceptee)
            .toList();

        if (pending.isEmpty && accepted.isEmpty) {
          return const _EmptyView(
            icon: Icons.mark_email_unread_outlined,
            message: 'Aucune invitation',
            hint: 'Les invitations à rejoindre une tontine apparaîtront ici',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            final authState = context.read<AuthBloc>().state;
            if (authState is Authenticated) {
              context
                  .read<TontineClientBloc>()
                  .add(LoadMyInvitations(authState.user.telephone));
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pending.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Invitations en attente',
                  count: pending.length,
                  color: Colors.orange,
                ),
                const SizedBox(height: 8),
                ...pending.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _InvitationCard(demande: d),
                    )),
                if (accepted.isNotEmpty) const SizedBox(height: 16),
              ],
              if (accepted.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Tontines rejointes',
                  count: accepted.length,
                  color: Colors.green,
                ),
                const SizedBox(height: 8),
                ...accepted.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _InvitationCard(demande: d),
                    )),
              ],
            ],
          ),
        );
      },
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
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[700]),
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

class _InvitationCard extends StatelessWidget {
  final DemandeAdhesionEntity demande;
  const _InvitationCard({required this.demande});

  Color _statusColor(DemandeStatus s) => switch (s) {
        DemandeStatus.acceptee => Colors.green,
        DemandeStatus.refusee => Colors.red,
        _ => Colors.orange,
      };

  String _statusLabel(DemandeStatus s) => switch (s) {
        DemandeStatus.acceptee => 'Acceptée',
        DemandeStatus.refusee => 'Refusée',
        _ => 'En attente',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd/MM/yyyy');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    demande.tontineLibelle ?? 'Tontine #${demande.idTontine}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(demande.statut)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel(demande.statut),
                    style: TextStyle(
                      color: _statusColor(demande.statut),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (demande.dateEnvoi != null) ...[
              const SizedBox(height: 4),
              Text(
                'Invité le ${fmt.format(demande.dateEnvoi!)}',
                style:
                    const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            if (demande.statut == DemandeStatus.envoyee)
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
                          foregroundColor: Colors.red),
                      child: const Text('Refuser'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          context.read<TontineClientBloc>().add(
                                RespondToInvitation(
                                  idDemande: demande.idDemandeAdhesion,
                                  response: DemandeStatus.acceptee,
                                ),
                              ),
                      child: const Text('Accepter'),
                    ),
                  ),
                ],
              )
            else if (demande.statut == DemandeStatus.acceptee &&
                demande.idTontine != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.push(
                        '/tontines/${demande.idTontine}/member',
                        extra: demande.tontineLibelle,
                      ),
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: const Text('Consulter la tontine'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Formulaire de création de tontine
// ──────────────────────────────────────────────────────────────────────────────

class _CreateTontineSheet extends StatefulWidget {
  const _CreateTontineSheet();

  @override
  State<_CreateTontineSheet> createState() => _CreateTontineSheetState();
}

class _CreateTontineSheetState extends State<_CreateTontineSheet> {
  final _formKey = GlobalKey<FormState>();
  final _libelleCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  String? _periodicite;
  DateTime? _dateDebut;
  DateTime? _dateFin;

  final _periodicites = ['quotidienne', 'hebdomadaire', 'mensuelle', 'trimestrielle', 'annuelle'];
  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void dispose() {
    _libelleCtrl.dispose();
    _montantCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isDebut}) async {
    final initial = isDebut ? _dateDebut : _dateFin;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      if (isDebut) {
        _dateDebut = picked;
      } else {
        _dateFin = picked;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    context.read<TontineClientBloc>().add(CreateTontine(
          libelle: _libelleCtrl.text.trim(),
          montant: double.parse(_montantCtrl.text.trim()),
          periodicite: _periodicite,
          description: _descriptionCtrl.text.trim().isEmpty
              ? null
              : _descriptionCtrl.text.trim(),
          dateDebut: _dateDebut,
          dateFin: _dateFin,
          idUser: authState.user.idUser,
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
                'Nouvelle tontine',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _libelleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom de la tontine *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.savings_outlined),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _montantCtrl,
                decoration: const InputDecoration(
                  labelText: 'Montant de cotisation (FCFA) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Champ requis';
                  if (double.tryParse(v.trim()) == null) return 'Montant invalide';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _periodicite,
                decoration: const InputDecoration(
                  labelText: 'Périodicité',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.repeat),
                ),
                items: _periodicites
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _periodicite = v),
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
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              BlocBuilder<TontineClientBloc, TontineClientState>(
                buildWhen: (prev, curr) =>
                    prev.createTontineStatus != curr.createTontineStatus,
                builder: (context, state) {
                  final loading =
                      state.createTontineStatus == TontineLoadStatus.loading;
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
                          : const Text('Créer la tontine'),
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
          style: TextStyle(
            color: date != null ? null : Colors.grey,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Widgets utilitaires
// ──────────────────────────────────────────────────────────────────────────────

class _UnauthenticatedView extends StatelessWidget {
  const _UnauthenticatedView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              'Connexion requise',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Vous devez être connecté pour accéder aux tontines et gérer vos cotisations.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => context.push('/login', extra: '/tontines'),
              icon: const Icon(Icons.login),
              label: const Text('Se connecter'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/register', extra: '/tontines'),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Créer un compte'),
            ),
          ],
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
            Text(
              message,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
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
