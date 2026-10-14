import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../data/paiement_models.dart';
import '../../data/paiement_service.dart';

/// Écran de paiement réutilisable (commande, tranche, cotisation de tontine).
///
/// Étapes : choix du mode (catégorie puis fournisseur) → formulaire → envoi →
/// attente de validation (téléphone ou authentification 3DS) → résultat.
/// Renvoie un [IssuePaiement] à la page appelante (ou null si l'utilisateur quitte avant de payer).
class PaiementPage extends StatefulWidget {
  final PaiementArgs args;
  const PaiementPage({super.key, required this.args});

  @override
  State<PaiementPage> createState() => _PaiementPageState();
}

enum _Etape { choix, formulaire, attente, succes, echec }

class _PaiementPageState extends State<PaiementPage> with WidgetsBindingObserver {
  final PaiementService _service = getIt<PaiementService>();
  final _fmt = NumberFormat('#,##0', 'fr_FR');

  // Référentiel
  List<CategoriePaiement> _categories = [];
  bool _chargement = true;
  String? _erreurChargement;

  // Sélection
  CategoriePaiement? _categorie;
  MoyenPaiement? _moyen;

  // Formulaire
  final _formKey = GlobalKey<FormState>();
  final _montantKey = GlobalKey<FormState>();
  late final TextEditingController _montantCtrl;
  final _telCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _paysCtrl = TextEditingController(text: 'Niger');
  final _carteCtrl = TextEditingController();
  final _expirationCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  // Envoi / suivi
  _Etape _etape = _Etape.choix;
  bool _envoi = false;
  ResultatPaiement? _resultat;
  String? _messageErreur;
  Timer? _polling;
  DateTime? _debutAttente;
  bool _verification = false;

  static const _intervalle = Duration(seconds: 5);
  static const _dureeMaxAttente = Duration(minutes: 3);

  double get _montant =>
      double.tryParse(_montantCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _montantCtrl = TextEditingController(text: widget.args.montant.toStringAsFixed(0));

    _preremplirPayeur();
    _chargerMoyens();
  }

  /// Pré-remplit le téléphone et le nom du payeur avec l'utilisateur connecté.
  Future<void> _preremplirPayeur() async {
    final user = await getIt<AuthLocalDataSource>().getCachedUser();
    if (!mounted || user == null) return;
    setState(() {
      if (_telCtrl.text.isEmpty) _telCtrl.text = user.telephone;
      final p = user.personne;
      if (_nomCtrl.text.isEmpty && p != null) {
        _nomCtrl.text = '${p.prenom} ${p.nom}'.trim();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _polling?.cancel();
    for (final c in [_montantCtrl, _telCtrl, _nomCtrl, _paysCtrl, _carteCtrl, _expirationCtrl, _cvvCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Retour dans l'application (après la page de la banque ou l'appli Mobile Money) :
  /// on vérifie tout de suite le statut.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _etape == _Etape.attente) {
      _verifier();
    }
  }

  // ─── Chargement ──────────────────────────────────────────────────────────

  Future<void> _chargerMoyens() async {
    setState(() {
      _chargement = true;
      _erreurChargement = null;
    });
    try {
      final categories = await _service.getMoyens();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _chargement = false;
        if (categories.length == 1) _choisirCategorie(categories.first);
      });
    } on PaiementException catch (e) {
      if (!mounted) return;
      setState(() {
        _erreurChargement = e.message;
        _chargement = false;
      });
    }
  }

  void _choisirCategorie(CategoriePaiement c) {
    _categorie = c;
    // Carte : la marque est déduite du numéro saisi ; un seul fournisseur → présélection
    _moyen = (c.estCarte || c.moyens.length == 1) ? c.moyens.first : null;
  }

  // ─── Envoi du paiement ───────────────────────────────────────────────────

  Future<void> _payer() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final categorie = _categorie!;
    final taille = MediaQuery.of(context).size;

    final corps = <String, dynamic>{
      'moyenPaiement': categorie.estCarte ? CodesCategorie.carte : _moyen!.code,
      'typeOperation': widget.args.typeOperation.code,
      'operationId': widget.args.operationId,
      'montant': _montant.round(),
      'nomPrenom': _nomCtrl.text.trim(),
      if (widget.args.periodeVersementId != null)
        'periodeVersementId': widget.args.periodeVersementId,
      if (!categorie.estCarte) 'numeroTelephone': _telCtrl.text.trim(),
      if (categorie.code == CodesCategorie.sta) 'paysPayeur': _paysCtrl.text.trim(),
      if (categorie.estCarte) ...{
        'numeroCarte': _carteCtrl.text.replaceAll(' ', ''),
        'dateExpiration': _expirationCtrl.text.trim(),
        'cvv': _cvvCtrl.text.trim(),
        'hauteurEcran': taille.height.round(),
        'largeurEcran': taille.width.round(),
      },
    };

    setState(() => _envoi = true);
    try {
      final resultat = await _service.payer(corps);
      // Ne pas garder les données de carte en mémoire plus longtemps que nécessaire
      _cvvCtrl.clear();
      if (!mounted) return;
      setState(() => _envoi = false);
      _traiterResultat(resultat);

      if (resultat.statut == StatutPaiement.enAttente && resultat.lienAuthentification != null) {
        await _ouvrirAuthentification(resultat.lienAuthentification!);
      }
    } on PaiementException catch (e) {
      if (!mounted) return;
      setState(() => _envoi = false);
      _afficherErreur(e.message);
    }
  }

  void _traiterResultat(ResultatPaiement r) {
    setState(() => _resultat = r);
    switch (r.statut) {
      case StatutPaiement.reussie:
        _polling?.cancel();
        setState(() => _etape = _Etape.succes);
      case StatutPaiement.echouee:
        _polling?.cancel();
        setState(() {
          _messageErreur = r.message;
          _etape = _Etape.echec;
        });
      case StatutPaiement.enAttente:
        if (_etape != _Etape.attente) {
          _debutAttente = DateTime.now();
          setState(() => _etape = _Etape.attente);
          _polling?.cancel();
          _polling = Timer.periodic(_intervalle, (_) => _verifier());
        }
    }
  }

  Future<void> _verifier() async {
    final ref = _resultat?.referenceExterne;
    if (ref == null || ref.isEmpty || _verification) return;
    if (_debutAttente != null && DateTime.now().difference(_debutAttente!) > _dureeMaxAttente) {
      _polling?.cancel();   // l'utilisateur peut toujours vérifier manuellement
    }
    _verification = true;
    try {
      final r = await _service.verifierStatut(ref);
      if (!mounted) return;
      // Conserver le lien 3DS de la réponse initiale
      _traiterResultat(r.statut == StatutPaiement.enAttente
          ? _resultat!.copyWith(statut: r.statut)
          : r);
    } on PaiementException catch (_) {
      // Erreur réseau ponctuelle : on réessaiera au prochain passage
    } finally {
      _verification = false;
    }
  }

  Future<void> _ouvrirAuthentification(String lien) async {
    final uri = Uri.tryParse(lien);
    if (uri == null) return;
    final ouvert = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!ouvert) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _afficherErreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _terminer() {
    final r = _resultat;
    Navigator.of(context).pop(
      r == null ? null : IssuePaiement(r.statut, r.referenceExterne),
    );
  }

  // ─── Construction de l'écran ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _etape != _Etape.attente && _etape != _Etape.succes,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _terminer();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.args.titre),
          leading: _etape == _Etape.formulaire
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _etape = _Etape.choix),
                )
              : null,
        ),
        body: SafeArea(child: _contenu()),
      ),
    );
  }

  Widget _contenu() {
    switch (_etape) {
      case _Etape.choix:
        return _ecranChoix();
      case _Etape.formulaire:
        return _ecranFormulaire();
      case _Etape.attente:
        return _ecranAttente();
      case _Etape.succes:
        return _ecranResultat(succes: true);
      case _Etape.echec:
        return _ecranResultat(succes: false);
    }
  }

  // ── Étape 1 : choix du mode de paiement ─────────────────────────────────

  Widget _ecranChoix() {
    final theme = Theme.of(context);
    if (_chargement) return const Center(child: CircularProgressIndicator());
    if (_erreurChargement != null) {
      return _MessageCentre(
        icone: Icons.wifi_off_outlined,
        titre: _erreurChargement!,
        action: FilledButton(onPressed: _chargerMoyens, child: const Text('Réessayer')),
      );
    }
    if (_categories.isEmpty) {
      return const _MessageCentre(
        icone: Icons.payments_outlined,
        titre: 'Aucun moyen de paiement disponible pour le moment.',
      );
    }

    final categorie = _categorie;
    final peutContinuer = categorie != null && _moyen != null;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _CarteMontant(
                args: widget.args,
                controller: _montantCtrl,
                formKey: _montantKey,
                fmt: _fmt,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 24),
              Text('Mode de paiement',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ..._categories.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TuileCategorie(
                      categorie: c,
                      selectionnee: categorie?.code == c.code,
                      onTap: () => setState(() => _choisirCategorie(c)),
                    ),
                  )),
              if (categorie != null) ...[
                const SizedBox(height: 14),
                Text(
                  categorie.estCarte ? 'Cartes acceptées' : 'Choisissez votre fournisseur',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.95,
                  children: categorie.moyens
                      .map((m) => _TuileMoyen(
                            moyen: m,
                            // Carte : simple affichage des logos, la marque vient du numéro
                            selectionne: !categorie.estCarte && _moyen?.code == m.code,
                            onTap: categorie.estCarte ? null : () => setState(() => _moyen = m),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        _BarreAction(
          libelle: 'Continuer',
          onPressed: peutContinuer
              ? () {
                  if (!(_montantKey.currentState?.validate() ?? true)) return;
                  setState(() => _etape = _Etape.formulaire);
                }
              : null,
        ),
      ],
    );
  }

  // ── Étape 2 : formulaire ────────────────────────────────────────────────

  Widget _ecranFormulaire() {
    final theme = Theme.of(context);
    final categorie = _categorie!;
    return Column(
      children: [
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Rappel du choix
                Row(
                  children: [
                    if (!categorie.estCarte && _moyen != null)
                      _Logo(moyen: _moyen!, taille: 44)
                    else
                      Icon(Icons.credit_card, size: 40, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(categorie.estCarte ? 'Carte bancaire' : _moyen!.libelle,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text('${_fmt.format(_montant)} FCFA',
                              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (categorie.estCarte) ..._champsCarte() else ..._champsTelephone(categorie),
                const SizedBox(height: 16),
                _NoteSecurite(carte: categorie.estCarte),
              ],
            ),
          ),
        ),
        _BarreAction(
          libelle: 'Payer ${_fmt.format(_montant)} FCFA',
          chargement: _envoi,
          onPressed: _envoi ? null : _payer,
        ),
      ],
    );
  }

  List<Widget> _champsTelephone(CategoriePaiement categorie) {
    final sta = categorie.code == CodesCategorie.sta;
    return [
      TextFormField(
        controller: _telCtrl,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
        decoration: InputDecoration(
          labelText: 'Numéro ${_moyen?.libelle ?? ''} *',
          prefixIcon: const Icon(Icons.phone_android_outlined),
          helperText: sta ? 'Format international accepté, ex. +227 96 00 00 00' : 'Ex. 96 00 00 00',
        ),
        validator: (v) {
          final chiffres = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
          if (chiffres.length < 8) return 'Numéro invalide';
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _nomCtrl,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Nom et prénom *',
          prefixIcon: Icon(Icons.person_outline),
        ),
        validator: (v) => (v == null || v.trim().length < 2) ? 'Indiquez votre nom' : null,
      ),
      if (sta) ...[
        const SizedBox(height: 16),
        TextFormField(
          controller: _paysCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Pays *',
            prefixIcon: Icon(Icons.public_outlined),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Indiquez le pays' : null,
        ),
      ],
    ];
  }

  List<Widget> _champsCarte() {
    final marque = detecterMarqueCarte(_carteCtrl.text);
    return [
      TextFormField(
        controller: _nomCtrl,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(
          labelText: 'Titulaire de la carte *',
          prefixIcon: Icon(Icons.person_outline),
        ),
        validator: (v) => (v == null || v.trim().length < 2) ? 'Indiquez le nom du titulaire' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _carteCtrl,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.creditCardNumber],
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(19),
          _NumeroCarteFormatter(),
        ],
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: 'Numéro de carte *',
          prefixIcon: const Icon(Icons.credit_card),
          suffixIcon: marque == null
              ? null
              : Padding(
                  padding: const EdgeInsets.all(10),
                  child: _BadgeMarque(marque: marque, categorie: _categorie!),
                ),
        ),
        validator: (v) {
          final chiffres = (v ?? '').replaceAll(' ', '');
          if (chiffres.length < 13 || !luhnValide(chiffres)) return 'Numéro de carte invalide';
          if (detecterMarqueCarte(chiffres) == null) return 'Seules les cartes Visa et MasterCard sont acceptées';
          return null;
        },
      ),
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: _expirationCtrl,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.creditCardExpirationDate],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
                _ExpirationFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Expiration *',
                hintText: 'MM/AA',
                prefixIcon: Icon(Icons.event_outlined),
              ),
              validator: _validerExpiration,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _cvvCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              autofillHints: const [AutofillHints.creditCardSecurityCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(
                labelText: 'CVV *',
                hintText: '3 chiffres',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) => (v == null || v.length < 3) ? 'CVV invalide' : null,
            ),
          ),
        ],
      ),
    ];
  }

  String? _validerExpiration(String? v) {
    final chiffres = (v ?? '').replaceAll('/', '');
    if (chiffres.length != 4) return 'Format MM/AA';
    final mois = int.tryParse(chiffres.substring(0, 2)) ?? 0;
    final annee = 2000 + (int.tryParse(chiffres.substring(2)) ?? 0);
    if (mois < 1 || mois > 12) return 'Mois invalide';
    final maintenant = DateTime.now();
    if (annee < maintenant.year || (annee == maintenant.year && mois < maintenant.month)) {
      return 'Carte expirée';
    }
    return null;
  }

  // ── Étape 3 : attente de validation ─────────────────────────────────────

  Widget _ecranAttente() {
    final theme = Theme.of(context);
    final carte = _categorie?.estCarte ?? false;
    final lien = _resultat?.lienAuthentification;
    final delaiDepasse = _debutAttente != null &&
        DateTime.now().difference(_debutAttente!) > _dureeMaxAttente;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Center(
          child: SizedBox(
            width: 72,
            height: 72,
            child: CircularProgressIndicator(strokeWidth: 5, color: theme.colorScheme.primary),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          carte ? 'Authentification bancaire' : 'Validez le paiement sur votre téléphone',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          carte
              ? 'Terminez la vérification demandée par votre banque, puis revenez dans l\'application.'
              : 'Une demande de ${_fmt.format(_montant)} FCFA a été envoyée au ${_telCtrl.text.trim()}. '
                  'Confirmez-la avec votre code secret ${_moyen?.libelle ?? ''}.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 16),
        Text(
          delaiDepasse
              ? 'Le paiement n\'est pas encore confirmé. Vous pouvez vérifier à nouveau ou revenir plus tard : '
                  'il sera mis à jour automatiquement.'
              : 'Vérification automatique en cours…',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        if (_resultat?.referenceExterne.isNotEmpty ?? false) ...[
          const SizedBox(height: 12),
          Text('Référence : ${_resultat!.referenceExterne}',
              textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: 32),
        if (carte && lien != null) ...[
          FilledButton.icon(
            onPressed: () => _ouvrirAuthentification(lien),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Ouvrir la page de ma banque'),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: _verification ? null : _verifier,
          icon: const Icon(Icons.refresh),
          label: const Text('J\'ai validé, vérifier maintenant'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _terminer,
          child: const Text('Fermer (le paiement continuera d\'être suivi)'),
        ),
      ],
    );
  }

  // ── Étape 4 : résultat ──────────────────────────────────────────────────

  Widget _ecranResultat({required bool succes}) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 40),
        Icon(succes ? Icons.check_circle : Icons.error_outline,
            size: 96, color: succes ? Colors.green : Colors.red),
        const SizedBox(height: 20),
        Text(
          succes ? 'Paiement réussi' : 'Paiement non abouti',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          succes
              ? '${_fmt.format(_montant)} FCFA ont bien été payés. Merci !'
              : (_messageErreur?.isNotEmpty ?? false)
                  ? _messageErreur!
                  : 'Le paiement a été refusé ou annulé. Aucun montant n\'a été débité.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
        ),
        if (_resultat?.referenceExterne.isNotEmpty ?? false) ...[
          const SizedBox(height: 12),
          Text('Référence : ${_resultat!.referenceExterne}',
              textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: 32),
        if (!succes) ...[
          FilledButton(
            onPressed: () => setState(() {
              _resultat = null;
              _messageErreur = null;
              _etape = _Etape.choix;
            }),
            child: const Text('Réessayer'),
          ),
          const SizedBox(height: 12),
        ],
        succes
            ? FilledButton(onPressed: _terminer, child: const Text('Terminer'))
            : OutlinedButton(onPressed: _terminer, child: const Text('Fermer')),
      ],
    );
  }
}

// ─── Détection de carte (mêmes règles que le backend) ──────────────────────

/// 'VISA', 'MASTERCARD' ou null.
String? detecterMarqueCarte(String numero) {
  final c = numero.replaceAll(RegExp(r'[^0-9]'), '');
  if (c.startsWith('4')) return 'VISA';
  if (c.length >= 2) {
    final deux = int.parse(c.substring(0, 2));
    if (deux >= 51 && deux <= 55) return 'MASTERCARD';
  }
  if (c.length >= 4) {
    final quatre = int.parse(c.substring(0, 4));
    if (quatre >= 2221 && quatre <= 2720) return 'MASTERCARD';
  }
  return null;
}

bool luhnValide(String chiffres) {
  var somme = 0;
  var doubler = false;
  for (var i = chiffres.length - 1; i >= 0; i--) {
    var d = chiffres.codeUnitAt(i) - 48;
    if (d < 0 || d > 9) return false;
    if (doubler) {
      d *= 2;
      if (d > 9) d -= 9;
    }
    somme += d;
    doubler = !doubler;
  }
  return somme % 10 == 0;
}

// ─── Widgets ───────────────────────────────────────────────────────────────

class _CarteMontant extends StatelessWidget {
  final PaiementArgs args;
  final TextEditingController controller;
  final GlobalKey<FormState> formKey;
  final NumberFormat fmt;
  final VoidCallback onChanged;

  const _CarteMontant({
    required this.args,
    required this.controller,
    required this.formKey,
    required this.fmt,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (args.sousTitre != null)
            Text(args.sousTitre!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700)),
          const SizedBox(height: 6),
          if (args.montantModifiable)
            Form(
              key: formKey,
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => onChanged(),
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Montant à payer (FCFA)',
                  helperText: args.montantMax != null
                      ? 'Maximum : ${fmt.format(args.montantMax)} FCFA'
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) {
                  final m = double.tryParse(v ?? '') ?? 0;
                  if (m <= 0) return 'Montant invalide';
                  if (args.montantMax != null && m > args.montantMax!) {
                    return 'Maximum ${fmt.format(args.montantMax)} FCFA';
                  }
                  return null;
                },
              ),
            )
          else
            Text('${fmt.format(args.montant)} FCFA',
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
        ],
      ),
    );
  }
}

class _TuileCategorie extends StatelessWidget {
  final CategoriePaiement categorie;
  final bool selectionnee;
  final VoidCallback onTap;

  const _TuileCategorie({required this.categorie, required this.selectionnee, required this.onTap});

  IconData get _icone {
    switch (categorie.code) {
      case CodesCategorie.carte:
        return Icons.credit_card;
      case CodesCategorie.sta:
        return Icons.currency_exchange;
      default:
        return Icons.phone_android;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleur = selectionnee ? theme.colorScheme.primary : Colors.grey.shade600;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectionnee ? theme.colorScheme.primary : Colors.grey.shade300,
            width: selectionnee ? 2 : 1,
          ),
          color: selectionnee ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(_icone, color: couleur, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(categorie.libelle,
                      style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold, color: selectionnee ? theme.colorScheme.primary : null)),
                  if (categorie.description != null && categorie.description!.isNotEmpty)
                    Text(categorie.description!,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ],
              ),
            ),
            // Aperçu des logos de la catégorie
            ...categorie.moyens.take(3).map((m) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: _Logo(moyen: m, taille: 26),
                )),
            if (selectionnee) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _TuileMoyen extends StatelessWidget {
  final MoyenPaiement moyen;
  final bool selectionne;
  final VoidCallback? onTap;

  const _TuileMoyen({required this.moyen, required this.selectionne, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectionne ? theme.colorScheme.primary : Colors.grey.shade300,
            width: selectionne ? 2 : 1,
          ),
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Logo(moyen: moyen, taille: 48),
            const SizedBox(height: 8),
            Text(moyen.libelle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: selectionne ? FontWeight.bold : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

/// Logo d'un moyen de paiement (image du back-office, sinon initiale).
class _Logo extends StatelessWidget {
  final MoyenPaiement moyen;
  final double taille;
  const _Logo({required this.moyen, required this.taille});

  @override
  Widget build(BuildContext context) {
    final url = moyen.logoUrl;
    final initiale = Container(
      width: taille,
      height: taille,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(taille / 4),
      ),
      child: Text(
        moyen.libelle.isNotEmpty ? moyen.libelle[0].toUpperCase() : '?',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: taille * 0.45),
      ),
    );
    if (url == null) return initiale;
    return ClipRRect(
      borderRadius: BorderRadius.circular(taille / 4),
      child: CachedNetworkImage(
        imageUrl: url,
        width: taille,
        height: taille,
        fit: BoxFit.contain,
        placeholder: (_, __) => SizedBox(width: taille, height: taille),
        errorWidget: (_, __, ___) => initiale,
      ),
    );
  }
}

/// Logo de la marque détectée dans le champ numéro de carte.
class _BadgeMarque extends StatelessWidget {
  final String marque;
  final CategoriePaiement categorie;
  const _BadgeMarque({required this.marque, required this.categorie});

  @override
  Widget build(BuildContext context) {
    final moyen = categorie.moyens.where((m) => m.code == marque).cast<MoyenPaiement?>().firstWhere(
          (m) => m != null,
          orElse: () => null,
        );
    if (moyen != null && moyen.logoUrl != null) return _Logo(moyen: moyen, taille: 28);
    return Text(marque == 'VISA' ? 'VISA' : 'MC',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12));
  }
}

class _NoteSecurite extends StatelessWidget {
  final bool carte;
  const _NoteSecurite({required this.carte});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_outlined, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              carte
                  ? 'Paiement sécurisé. Vos données de carte ne sont pas conservées par Kassouwata. '
                      'Votre banque peut vous demander une vérification supplémentaire.'
                  : 'Vous recevrez une demande de confirmation sur votre téléphone. '
                      'Gardez-le à portée de main.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarreAction extends StatelessWidget {
  final String libelle;
  final VoidCallback? onPressed;
  final bool chargement;
  const _BarreAction({required this.libelle, required this.onPressed, this.chargement = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onPressed,
          child: chargement
              ? const SizedBox(
                  height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(libelle),
        ),
      ),
    );
  }
}

class _MessageCentre extends StatelessWidget {
  final IconData icone;
  final String titre;
  final Widget? action;
  const _MessageCentre({required this.icone, required this.titre, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(titre, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// 4242424242424242 -> 4242 4242 4242 4242
class _NumeroCarteFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final chiffres = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < chiffres.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(chiffres[i]);
    }
    final texte = buffer.toString();
    return TextEditingValue(text: texte, selection: TextSelection.collapsed(offset: texte.length));
  }
}

/// 1227 -> 12/27
class _ExpirationFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final chiffres = newValue.text.replaceAll('/', '');
    final texte = chiffres.length > 2 ? '${chiffres.substring(0, 2)}/${chiffres.substring(2)}' : chiffres;
    return TextEditingValue(text: texte, selection: TextSelection.collapsed(offset: texte.length));
  }
}
