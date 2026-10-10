import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/demande_entity.dart';
import '../bloc/tontine_client_bloc.dart';

class TontinePeriodsPage extends StatefulWidget {
  final int tontineId;
  const TontinePeriodsPage({super.key, required this.tontineId});

  @override
  State<TontinePeriodsPage> createState() => _TontinePeriodsPageState();
}

class _TontinePeriodsPageState extends State<TontinePeriodsPage> {
  @override
  void initState() {
    super.initState();
    context
        .read<TontineClientBloc>()
        .add(LoadPeriodes(widget.tontineId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Périodes de versement')),
      body: BlocConsumer<TontineClientBloc, TontineClientState>(
        listener: (context, state) {
          if (state.versementStatus == TontineLoadStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Cotisation envoyée avec succès !'),
              backgroundColor: Colors.green,
            ));
            // Reload
            context
                .read<TontineClientBloc>()
                .add(LoadPeriodes(widget.tontineId));
          }
          if (state.versementStatus == TontineLoadStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.errorMessage ?? 'Erreur'),
              backgroundColor: Colors.red,
            ));
          }
        },
        builder: (context, state) {
          if (state.periodesStatus == TontineLoadStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.periodesStatus == TontineLoadStatus.failure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(state.errorMessage ?? 'Erreur'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context
                        .read<TontineClientBloc>()
                        .add(LoadPeriodes(widget.tontineId)),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (state.periodes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucune période définie',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.periodes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final periode = state.periodes[index];
              return _PeriodeCard(
                  periode: periode, tontineId: widget.tontineId);
            },
          );
        },
      ),
    );
  }
}

class _PeriodeCard extends StatelessWidget {
  final PeriodeVersementEntity periode;
  final int tontineId;
  const _PeriodeCard({required this.periode, required this.tontineId});

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
            Text(
              periode.libelle ?? 'Période #${periode.idTontinePeriodeVersement}',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (periode.dateDebut != null || periode.dateFin != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.date_range_outlined,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  [
                    if (periode.dateDebut != null)
                      fmt.format(periode.dateDebut!),
                    if (periode.dateFin != null) fmt.format(periode.dateFin!),
                  ].join(' → '),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ]),
            ],
            if (periode.beneficiaireTelephone != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.person_outline,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Bénéficiaire : ${periode.beneficiaireTelephone}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showVersementSheet(context, periode),
                icon: const Icon(Icons.send, size: 18),
                label: const Text('Envoyer ma cotisation'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVersementSheet(
      BuildContext context, PeriodeVersementEntity periode) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    final montantCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Envoyer ma cotisation',
                style: Theme.of(ctx)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: montantCtrl,
              decoration: const InputDecoration(
                labelText: 'Montant (FCFA)',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final montant = double.tryParse(montantCtrl.text);
                  if (montant == null || montant <= 0) return;
                  context.read<TontineClientBloc>().add(SendVersement(
                        idPeriode: periode.idTontinePeriodeVersement,
                        montant: montant,
                        membreTelephone: authState.user.telephone,
                        membreIdUser: authState.user.idUser,
                      ));
                  Navigator.of(ctx).pop();
                },
                child: const Text('Confirmer'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
