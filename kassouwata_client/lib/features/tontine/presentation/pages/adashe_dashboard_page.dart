import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/widgets/connexion_requise.dart';
import '../../../../espaces/espace.dart';
import '../../../../espaces/espace_auth.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/demande_entity.dart';
import '../../domain/repositories/tontine_client_repository.dart';
import 'tontine_list_page.dart' show ouvrirCreationAdashe;
import '../../../../espaces/espace_menu.dart';
import '../widgets/adashe_produit_widgets.dart';

/// Dashboard Adashen Waya : les chiffres des Adashé de l'utilisateur.
class AdasheDashboardPage extends StatelessWidget {
  const AdasheDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (a, b) =>
          b is Authenticated || b is Unauthenticated || b is KycPending,
      builder: (context, auth) {
        if (auth is! Authenticated) {
          return Scaffold(
            appBar: AppBar(leading: const BoutonMenu(), title: const Text('Adashen Waya')),
            body: const ConnexionRequise(
              titre: 'Adashen Waya',
              texte: 'Connectez-vous pour suivre vos Adashé et vos cotisations.',
              redirectTo: '/adashe',
            ),
          );
        }
        return _Tableau(key: ValueKey(auth.user.idUser));
      },
    );
  }
}

// ── Données calculées ─────────────────────────────────────────────────────────

class _Echeance {
  final TontineEntity tontine;
  final PeriodeVersementEntity periode;
  final bool payee;
  const _Echeance(this.tontine, this.periode, this.payee);
}

class _Chiffres {
  final int crees;
  final int rejoints;
  final int invitations;
  final double totalCotise;
  final int nbCotisations;
  /// Engagement par période : somme des montants des Adashé actifs
  final double engagementParPeriode;
  /// Périodes en cours, payées ou non
  final List<_Echeance> enCours;
  /// Prochain tour de l'utilisateur (il est bénéficiaire)
  final _Echeance? prochainTour;
  final List<TontineEntity> adashes;

  const _Chiffres({
    required this.crees,
    required this.rejoints,
    required this.invitations,
    required this.totalCotise,
    required this.nbCotisations,
    required this.engagementParPeriode,
    required this.enCours,
    required this.prochainTour,
    required this.adashes,
  });

  List<_Echeance> get aPayer => enCours.where((e) => !e.payee).toList();
  double get montantAPayer =>
      aPayer.fold(0, (s, e) => s + e.tontine.montant);
}

class _Tableau extends StatefulWidget {
  const _Tableau({super.key});

  @override
  State<_Tableau> createState() => _TableauState();
}

class _TableauState extends State<_Tableau> {
  final _repo = getIt<TontineClientRepository>();
  late Future<_Chiffres> _chiffres;

  @override
  void initState() {
    super.initState();
    _chiffres = _charger();
  }

  T _ou<T>(Either<Failure, T> r, T defaut) => r.fold((_) => defaut, (v) => v);

  Future<_Chiffres> _charger() async {
    final storage = getIt<SecureStorage>();
    final idUser = await storage.getUserId() ?? '';
    final tel = await storage.getTelephone() ?? '';

    final resultats = await Future.wait([
      _repo.getMyTontines(idUser),
      _repo.getMyInvitations(tel),
      _repo.getAllVersements(),
    ]);
    final creees = _ou<List<TontineEntity>>(
        resultats[0] as Either<Failure, List<TontineEntity>>, []);
    final demandes = _ou<List<DemandeAdhesionEntity>>(
        resultats[1] as Either<Failure, List<DemandeAdhesionEntity>>, []);
    final versements = _ou<List<TontineVersementEntity>>(
        resultats[2] as Either<Failure, List<TontineVersementEntity>>, []);

    // Adashé rejoints : invitations acceptées (hors Adashé créés par moi)
    final idsCrees = creees.map((t) => t.idTontine).toSet();
    final idsRejoints = demandes
        .where((d) =>
            d.statut == DemandeStatus.acceptee &&
            d.idTontine != null &&
            !idsCrees.contains(d.idTontine))
        .map((d) => d.idTontine!)
        .toSet();
    final rejoints = (await Future.wait(idsRejoints.map(_repo.getTontineById)))
        .map((r) => _ou<TontineEntity?>(r, null))
        .whereType<TontineEntity>()
        .toList();
    final adashes = [...creees, ...rejoints];

    // Mes cotisations
    final miennes = versements
        .where((v) =>
            (v.membreIdUser != null && v.membreIdUser == idUser) ||
            (v.membreIdUser == null && v.membreTelephone == tel))
        .toList();
    final periodesPayees =
        miennes.map((v) => v.idTontinePeriodeVersement).whereType<int>().toSet();
    final totalCotise = miennes.fold<double>(0, (s, v) => s + (v.montant ?? 0));

    // Périodes de chaque Adashé : en cours et prochain tour
    final maintenant = DateTime.now();
    final aujourdhui = DateTime(maintenant.year, maintenant.month, maintenant.day);
    final enCours = <_Echeance>[];
    _Echeance? prochainTour;
    double engagement = 0;
    final periodesParAdashe =
        await Future.wait(adashes.map((t) => _repo.getPeriodes(t.idTontine)));
    for (var i = 0; i < adashes.length; i++) {
      final t = adashes[i];
      final periodes = _ou<List<PeriodeVersementEntity>>(periodesParAdashe[i], []);
      var actif = false;
      for (final p in periodes) {
        final debut = p.dateDebut;
        final fin = p.dateFin;
        final commencee = debut == null || !debut.isAfter(maintenant);
        final pasFinie = fin == null || !fin.isBefore(aujourdhui);
        if (commencee && pasFinie) {
          actif = true;
          enCours.add(_Echeance(t, p, periodesPayees.contains(p.idTontinePeriodeVersement)));
        }
        if (p.beneficiaireTelephone == tel && pasFinie) {
          final e = _Echeance(t, p, false);
          if (prochainTour == null ||
              (debut != null &&
                  (prochainTour.periode.dateDebut == null ||
                      debut.isBefore(prochainTour.periode.dateDebut!)))) {
            prochainTour = e;
          }
        }
      }
      if (actif) engagement += t.montant;
    }
    enCours.sort((a, b) => (a.payee ? 1 : 0).compareTo(b.payee ? 1 : 0));

    return _Chiffres(
      crees: creees.length,
      rejoints: rejoints.length,
      invitations: demandes.where((d) => d.statut == DemandeStatus.envoyee).length,
      totalCotise: totalCotise,
      nbCotisations: miennes.length,
      engagementParPeriode: engagement,
      enCours: enCours,
      prochainTour: prochainTour,
      adashes: adashes,
    );
  }

  Future<void> _rafraichir() async {
    final f = _charger();
    setState(() => _chiffres = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    final couleur = Espace.adashe.couleur(context);
    return Scaffold(
      appBar: AppBar(
        leading: const BoutonMenu(),
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh),
            onPressed: _rafraichir,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: couleur,
        foregroundColor: Colors.white,
        onPressed: () async {
          if (await ouvrirCreationAdashe(context)) _rafraichir();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouvel Adashé'),
      ),
      body: FutureBuilder<_Chiffres>(
        future: _chiffres,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Impossible de charger vos chiffres.'),
                  const SizedBox(height: 8),
                  OutlinedButton(onPressed: _rafraichir, child: const Text('Réessayer')),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _rafraichir,
            child: _Contenu(c: snap.data!, couleur: couleur),
          );
        },
      ),
    );
  }
}

// ── Affichage ─────────────────────────────────────────────────────────────────

final _fcfa = NumberFormat.decimalPattern('fr_FR');
final _date = DateFormat('dd/MM/yyyy');
String _montant(double v) => '${_fcfa.format(v.round())} FCFA';

class _Contenu extends StatelessWidget {
  final _Chiffres c;
  final Color couleur;
  const _Contenu({required this.c, required this.couleur});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        // ── Chiffres clés ──
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: [
            _Chiffre(
              icone: Icons.groups_outlined,
              couleur: couleur,
              valeur: '${c.crees + c.rejoints}',
              libelle: 'Mes Adashé',
              detail: '${c.crees} créés · ${c.rejoints} rejoints',
            ),
            _Chiffre(
              icone: Icons.savings_outlined,
              couleur: Colors.green.shade700,
              valeur: _montant(c.totalCotise),
              libelle: 'Total cotisé',
              detail: '${c.nbCotisations} cotisation${c.nbCotisations > 1 ? 's' : ''}',
            ),
            _Chiffre(
              icone: Icons.schedule,
              couleur: c.aPayer.isEmpty ? Colors.green.shade700 : Colors.red.shade700,
              valeur: c.aPayer.isEmpty ? 'À jour' : _montant(c.montantAPayer),
              libelle: 'À payer maintenant',
              detail: c.aPayer.isEmpty
                  ? 'Aucune cotisation due'
                  : '${c.aPayer.length} cotisation${c.aPayer.length > 1 ? 's' : ''} due${c.aPayer.length > 1 ? 's' : ''}',
            ),
            _Chiffre(
              icone: Icons.mail_outline,
              couleur: theme.colorScheme.secondary,
              valeur: '${c.invitations}',
              libelle: 'Invitations',
              detail: 'En attente de réponse',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Engagement par période : ${_montant(c.engagementParPeriode)}',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
        ),

        // ── Prochain tour ──
        const SizedBox(height: 20),
        _Titre('Mon prochain tour'),
        if (c.prochainTour == null)
          const _Vide('Aucun tour prévu pour vous pour le moment.')
        else
          Card(
            margin: EdgeInsets.zero,
            color: couleur.withValues(alpha: 0.08),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: couleur,
                child: const Icon(Icons.emoji_events_outlined, color: Colors.white),
              ),
              title: Text(c.prochainTour!.tontine.libelle,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text([
                c.prochainTour!.periode.libelle ?? 'Période',
                if (c.prochainTour!.periode.dateDebut != null)
                  'à partir du ${_date.format(c.prochainTour!.periode.dateDebut!)}',
              ].join(' · ')),
              onTap: () => _ouvrir(context, c.prochainTour!.tontine),
            ),
          ),

        // ── Cotisations de la période en cours ──
        const SizedBox(height: 20),
        _Titre('Cotisations de la période en cours'),
        if (c.enCours.isEmpty)
          const _Vide('Aucune période de cotisation en cours.')
        else
          ...c.enCours.map((e) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(
                    e.payee ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: e.payee ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                  title: Text(e.tontine.libelle),
                  subtitle: Text([
                    e.periode.libelle ?? 'Période',
                    if (e.periode.dateFin != null)
                      'jusqu\'au ${_date.format(e.periode.dateFin!)}',
                  ].join(' · ')),
                  trailing: e.payee
                      ? Text('Payé',
                          style: TextStyle(
                              color: Colors.green.shade700, fontWeight: FontWeight.w600))
                      : FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: couleur),
                          onPressed: () => _ouvrir(context, e.tontine),
                          child: Text(_montant(e.tontine.montant)),
                        ),
                ),
              )),

        // ── Mes Adashé ──
        const SizedBox(height: 20),
        _Titre('Mes Adashé'),
        if (c.adashes.isEmpty)
          const _Vide('Vous ne participez à aucun Adashé. Créez-en un ou acceptez une invitation.')
        else
          ...c.adashes.map((t) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(Icons.groups_outlined, color: couleur),
                  title: Text(t.libelle),
                  subtitle: Text([
                    if (t.estProduit) 'Achat groupé',
                    _montant(t.montant),
                    if (t.periodicite != null) t.periodicite!,
                  ].join(' · ')),
                  trailing: t.estProduit
                      ? BadgeStatutAdashe(tontine: t)
                      : const Icon(Icons.chevron_right),
                  onTap: () => _ouvrir(context, t),
                ),
              )),
      ],
    );
  }

  void _ouvrir(BuildContext context, TontineEntity t) =>
      context.push('/tontines/${t.idTontine}', extra: t);
}

class _Chiffre extends StatelessWidget {
  final IconData icone;
  final Color couleur;
  final String valeur;
  final String libelle;
  final String detail;
  const _Chiffre({
    required this.icone,
    required this.couleur,
    required this.valeur,
    required this.libelle,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icone, color: couleur, size: 20),
            const SizedBox(width: 6),
            Expanded(
              child: Text(libelle,
                  style: theme.textTheme.labelLarge,
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(valeur,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold, color: couleur)),
          ),
          Text(detail,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _Titre extends StatelessWidget {
  final String texte;
  const _Titre(this.texte);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(texte,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      );
}

class _Vide extends StatelessWidget {
  final String texte;
  const _Vide(this.texte);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(texte, style: TextStyle(color: Colors.grey.shade600)),
      );
}
