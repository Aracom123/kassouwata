import 'package:flutter/material.dart';

import '../core/di/injection.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/dio_client.dart';
import '../features/tontine/presentation/widgets/adashe_produit_widgets.dart';
import 'vendeur_session.dart';

/// Espace Vendeur : Adashé Produit (achats groupés) portant sur mes produits.
/// Les demandes en attente sont acceptées ou refusées ici.
class DemandesAdashePage extends StatefulWidget {
  const DemandesAdashePage({super.key});

  @override
  State<DemandesAdashePage> createState() => _DemandesAdashePageState();
}

class _DemandesAdashePageState extends State<DemandesAdashePage> {
  late Future<List<AdasheProduitResume>> _liste;
  int? _enCours;

  @override
  void initState() {
    super.initState();
    _liste = _charger();
  }

  Future<List<AdasheProduitResume>> _charger() async {
    final boutique = await getIt<VendeurSession>().boutique();
    if (boutique == null) return [];
    final res = await getIt<DioClient>()
        .dio
        .get(ApiEndpoints.adasheProduitBoutique(boutique.idBoutique));
    final liste = (res.data as List)
        .map((e) => AdasheProduitResume.fromJson(e as Map<String, dynamic>))
        .toList();
    // Les demandes en attente d'abord
    liste.sort((a, b) => (a.statut == 'EN_ATTENTE_VENDEUR' ? 0 : 1)
        .compareTo(b.statut == 'EN_ATTENTE_VENDEUR' ? 0 : 1));
    return liste;
  }

  Future<void> _rafraichir() async {
    final f = _charger();
    setState(() => _liste = f);
    await f;
  }

  Future<void> _decider(AdasheProduitResume a, bool accepte) async {
    String? motif;
    if (!accepte) {
      final ctrl = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Refuser cet Adashé'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              labelText: 'Motif (envoyé au créateur)',
              hintText: 'Ex : stock insuffisant',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Refuser')),
          ],
        ),
      );
      if (ok != true) return;
      motif = ctrl.text.trim();
    }
    setState(() => _enCours = a.tontine.idTontine);
    try {
      await getIt<DioClient>().dio.post(
        ApiEndpoints.adasheProduitDecision(a.tontine.idTontine),
        data: {'accepte': accepte, if (motif != null && motif.isNotEmpty) 'motif': motif},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(accepte
            ? 'Adashé accepté : les périodes de cotisation sont créées et les membres prévenus.'
            : 'Adashé refusé : le créateur est prévenu.'),
        backgroundColor: accepte ? Colors.green : Colors.orange.shade800,
      ));
      await _rafraichir();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(messageErreur(e, 'Action impossible.')),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _enCours = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Achats groupés (Adashé)')),
      body: FutureBuilder<List<AdasheProduitResume>>(
        future: _liste,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: TextButton(onPressed: _rafraichir, child: const Text('Réessayer')),
            );
          }
          final liste = snap.data!;
          if (liste.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Aucun Adashé sur vos produits pour le moment.\n'
                  'Cochez « Payable en Adashé » sur un produit pour le proposer à l\'achat groupé.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _rafraichir,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: liste.length,
              itemBuilder: (context, i) {
                final a = liste[i];
                final t = a.tontine;
                final c = couleurStatut(a.statut);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(t.produitLibelle ?? t.libelle,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          BadgeStatutAdashe(tontine: t),
                        ]),
                        const SizedBox(height: 6),
                        Text('${a.membres}/${a.nombreMembres ?? '?'} membres · '
                            '${t.nombrePeriodes ?? '?'} périodes (${t.periodicite ?? ''}) · '
                            '${fcfa(t.montant)} / membre / période'),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: a.progression,
                          minHeight: 6,
                          color: c,
                          backgroundColor: c.withValues(alpha: 0.15),
                        ),
                        const SizedBox(height: 4),
                        Text('${fcfa(a.collecte)} réunis sur ${fcfa(a.montantCible)}',
                            style: const TextStyle(fontSize: 12)),
                        if (a.statut == 'EN_ATTENTE_VENDEUR') ...[
                          const SizedBox(height: 10),
                          if (_enCours == t.idTontine)
                            const LinearProgressIndicator()
                          else
                            Row(children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _decider(a, false),
                                  child: const Text('Refuser'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => _decider(a, true),
                                  child: const Text('Accepter'),
                                ),
                              ),
                            ]),
                        ],
                        if (a.statut == 'OBJECTIF_ATTEINT')
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text('Prix réuni : préparez la livraison du produit.',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
