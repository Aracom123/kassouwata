import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../espaces/espace.dart';
import '../../../../espaces/espace_auth.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../catalogue/domain/entities/product_entity.dart';
import '../../data/models/tontine_client_models.dart';
import '../../domain/entities/demande_entity.dart';

final _fcfa = NumberFormat.decimalPattern('fr_FR');
String fcfa(num v) => '${_fcfa.format(v.round())} FCFA';

/// Message d'erreur renvoyé par le serveur ({"error": "..."}).
String messageErreur(Object e, String defaut) {
  if (e is DioException) {
    final d = e.response?.data;
    if (d is Map && d['error'] is String) return d['error'] as String;
    if (d is Map && d['message'] is String) return d['message'] as String;
  }
  return defaut;
}

/// Résumé d'un Adashé Produit renvoyé par le serveur (avec la progression).
class AdasheProduitResume {
  final TontineEntity tontine;
  final String statut;
  final double montantCible;
  final double collecte;
  final int membres;
  final int? nombreMembres;
  final int? placesRestantes;

  const AdasheProduitResume({
    required this.tontine,
    required this.statut,
    required this.montantCible,
    required this.collecte,
    required this.membres,
    this.nombreMembres,
    this.placesRestantes,
  });

  factory AdasheProduitResume.fromJson(Map<String, dynamic> j) => AdasheProduitResume(
        tontine: TontineModel.fromJson(j['tontine'] as Map<String, dynamic>),
        statut: j['statut'] as String? ?? 'ACTIF',
        montantCible: (j['montantCible'] as num?)?.toDouble() ?? 0,
        collecte: (j['collecte'] as num?)?.toDouble() ?? 0,
        membres: (j['membres'] as num?)?.toInt() ?? 0,
        nombreMembres: (j['nombreMembres'] as num?)?.toInt(),
        placesRestantes: (j['placesRestantes'] as num?)?.toInt(),
      );

  double get progression =>
      montantCible <= 0 ? 0 : (collecte / montantCible).clamp(0, 1).toDouble();
}

Color couleurStatut(String statut) {
  switch (statut) {
    case 'EN_ATTENTE_VENDEUR':
      return Colors.orange.shade800;
    case 'REFUSE':
      return Colors.red.shade700;
    case 'OBJECTIF_ATTEINT':
      return Colors.green.shade700;
    default:
      return Colors.blue.shade700;
  }
}

class BadgeStatutAdashe extends StatelessWidget {
  final TontineEntity tontine;
  const BadgeStatutAdashe({super.key, required this.tontine});

  @override
  Widget build(BuildContext context) {
    final c = couleurStatut(tontine.statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(tontine.statutLibelle,
          style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Page produit : « Acheter en Adashé » ─────────────────────────────────────

/// Bloc affiché sur la fiche d'un produit payable en Adashé : créer un Adashé
/// pour ce produit, ou rejoindre un Adashé ouvert.
class AdasheProduitSection extends StatefulWidget {
  final ProductEntity produit;
  const AdasheProduitSection({super.key, required this.produit});

  @override
  State<AdasheProduitSection> createState() => _AdasheProduitSectionState();
}

class _AdasheProduitSectionState extends State<AdasheProduitSection> {
  final Dio _dio = getIt<DioClient>().dio;
  Future<List<AdasheProduitResume>>? _ouverts;
  int? _rejoindreEnCours;

  Future<List<AdasheProduitResume>> _charger() async {
    final res = await _dio.get(ApiEndpoints.adasheProduitOuverts(widget.produit.idProduit));
    return (res.data as List)
        .map((e) => AdasheProduitResume.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void _creer() {
    final auth = context.read<AuthBloc>().state;
    if (auth is! Authenticated) {
      context.push('/login', extra: '/products/${widget.produit.idProduit}');
      return;
    }
    context.push('/adashe-produit/nouveau', extra: widget.produit);
  }

  Future<void> _rejoindre(AdasheProduitResume a) async {
    setState(() => _rejoindreEnCours = a.tontine.idTontine);
    try {
      await _dio.post(ApiEndpoints.adasheProduitRejoindre(a.tontine.idTontine));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vous avez rejoint l\'Adashé. Retrouvez-le dans Adashen Waya.'),
        backgroundColor: Colors.green,
      ));
      setState(() => _ouverts = _charger());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(messageErreur(e, 'Impossible de rejoindre cet Adashé.')),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _rejoindreEnCours = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleur = Espace.adashe.couleur(context);
    final connecte = context.watch<AuthBloc>().state is Authenticated;
    if (connecte) _ouverts ??= _charger();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: couleur.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.groups_outlined, color: couleur),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Acheter en Adashé',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold, color: couleur)),
            ),
          ]),
          const SizedBox(height: 6),
          const Text('Réunissez un groupe : chacun cotise un petit montant à chaque '
              'période jusqu\'à réunir le prix du produit.'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: couleur),
              onPressed: _creer,
              icon: const Icon(Icons.add),
              label: const Text('Créer un Adashé pour ce produit'),
            ),
          ),
          if (connecte)
            FutureBuilder<List<AdasheProduitResume>>(
              future: _ouverts,
              builder: (context, snap) {
                final liste = snap.data ?? const [];
                if (liste.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text('Adashé ouverts à rejoindre',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    for (final a in liste)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                              '${fcfa(a.tontine.montant)} / membre · ${a.tontine.periodicite ?? ''}'),
                          subtitle: Text(
                              '${a.tontine.nombrePeriodes ?? '?'} périodes · '
                              '${a.membres}/${a.nombreMembres ?? '?'} membres · '
                              '${a.placesRestantes ?? 0} place(s)'),
                          trailing: _rejoindreEnCours == a.tontine.idTontine
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : OutlinedButton(
                                  onPressed: () => _rejoindre(a),
                                  child: const Text('Rejoindre'),
                                ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

// ── Détail d'un Adashé Produit : statut et progression ──────────────────────

class AdasheProduitStatutCard extends StatefulWidget {
  final int idTontine;
  const AdasheProduitStatutCard({super.key, required this.idTontine});

  @override
  State<AdasheProduitStatutCard> createState() => _AdasheProduitStatutCardState();
}

class _AdasheProduitStatutCardState extends State<AdasheProduitStatutCard> {
  late Future<AdasheProduitResume> _resume;

  @override
  void initState() {
    super.initState();
    _resume = _charger();
  }

  Future<AdasheProduitResume> _charger() async {
    final res = await getIt<DioClient>()
        .dio
        .get(ApiEndpoints.adasheProduitResume(widget.idTontine));
    return AdasheProduitResume.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<AdasheProduitResume>(
      future: _resume,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: LinearProgressIndicator(),
          );
        }
        final a = snap.data!;
        final t = a.tontine;
        final c = couleurStatut(a.statut);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: c.withValues(alpha: 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.shopping_bag_outlined, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(t.produitLibelle ?? 'Produit',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                BadgeStatutAdashe(tontine: t),
              ]),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: a.progression,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                color: c,
                backgroundColor: c.withValues(alpha: 0.15),
              ),
              const SizedBox(height: 6),
              Text('${fcfa(a.collecte)} réunis sur ${fcfa(a.montantCible)} · '
                  '${a.membres}/${a.nombreMembres ?? '?'} membres'),
              if (a.statut == 'EN_ATTENTE_VENDEUR')
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Les cotisations commenceront dès que le vendeur aura accepté.',
                      style: TextStyle(fontSize: 12)),
                ),
              if (a.statut == 'REFUSE' && (t.motifRefus ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Motif du refus : ${t.motifRefus}',
                      style: const TextStyle(fontSize: 12)),
                ),
              if (a.statut == 'OBJECTIF_ATTEINT')
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Le prix est réuni : le vendeur organise la livraison.',
                      style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        );
      },
    );
  }
}
