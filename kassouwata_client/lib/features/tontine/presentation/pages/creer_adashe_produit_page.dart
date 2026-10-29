import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../espaces/espace.dart';
import '../../../../espaces/espace_auth.dart';
import '../../../catalogue/domain/entities/product_entity.dart';
import '../widgets/adashe_produit_widgets.dart';

/// Créer un Adashé Produit : un groupe cotise pour acheter ce produit.
/// Le montant par membre et par période est calculé automatiquement.
class CreerAdasheProduitPage extends StatefulWidget {
  final ProductEntity produit;
  const CreerAdasheProduitPage({super.key, required this.produit});

  @override
  State<CreerAdasheProduitPage> createState() => _CreerAdasheProduitPageState();
}

class _CreerAdasheProduitPageState extends State<CreerAdasheProduitPage> {
  static const _periodicites = {
    'quotidienne': 'Chaque jour',
    'hebdomadaire': 'Chaque semaine',
    'mensuelle': 'Chaque mois',
    'trimestrielle': 'Chaque trimestre',
    'annuelle': 'Chaque année',
  };

  final _membresCtrl = TextEditingController(text: '5');
  final _periodesCtrl = TextEditingController(text: '6');
  String _periodicite = 'mensuelle';
  DateTime _debut = DateTime.now().add(const Duration(days: 1));
  bool _ouverte = true;
  bool _envoi = false;
  String? _erreur;

  int get _membres => int.tryParse(_membresCtrl.text) ?? 0;
  int get _periodes => int.tryParse(_periodesCtrl.text) ?? 0;
  bool get _valide =>
      _membres >= 2 && _membres <= 100 && _periodes >= 1 && _periodes <= 60;

  /// Même calcul que le serveur : prix / (membres × périodes), arrondi au franc supérieur
  double get _parMembre =>
      _valide ? (widget.produit.prix / (_membres * _periodes)).ceilToDouble() : 0;

  @override
  void dispose() {
    _membresCtrl.dispose();
    _periodesCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _debut,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _debut = d);
  }

  Future<void> _creer() async {
    if (!_valide) return;
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await getIt<DioClient>().dio.post(ApiEndpoints.adasheProduit, data: {
        'idProduit': widget.produit.idProduit,
        'periodicite': _periodicite,
        'nombrePeriodes': _periodes,
        'nombreMembres': _membres,
        'dateDebut': DateFormat('yyyy-MM-dd').format(_debut),
        'ouverte': _ouverte,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Adashé créé. Le vendeur doit maintenant l\'accepter : '
            'vous serez prévenu par SMS.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 5),
      ));
      await EspaceService.memoriser(Espace.adashe);
      if (mounted) context.go('/adashe');
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = messageErreur(e, 'La création de l\'Adashé a échoué.'));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleur = Espace.adashe.couleur(context);
    final p = widget.produit;

    return Scaffold(
      appBar: AppBar(title: const Text('Acheter en Adashé')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Produit ──
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Icons.shopping_bag_outlined, color: couleur),
                title: Text(p.libelle, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text([
                  fcfa(p.prix),
                  if (p.boutiqueName != null) p.boutiqueName!,
                ].join(' · ')),
              ),
            ),
            const SizedBox(height: 20),

            // ── Paramètres ──
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _membresCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Nombre de membres',
                    helperText: 'Vous compris (2 à 100)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _periodesCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Nombre de périodes',
                    helperText: '1 à 60',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _periodicite,
              decoration: const InputDecoration(
                labelText: 'Périodicité des cotisations',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final e in _periodicites.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _periodicite = v ?? 'mensuelle'),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _choisirDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Début souhaité',
                  helperText: 'Les cotisations démarrent après l\'accord du vendeur',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_debut)),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _ouverte,
              onChanged: (v) => setState(() => _ouverte = v),
              title: const Text('Ouvert au public'),
              subtitle: Text(_ouverte
                  ? 'Visible sur la page du produit : tout acheteur peut rejoindre. '
                      'Vous pouvez aussi inviter des numéros.'
                  : 'Sur invitation uniquement : vous invitez les membres par leur numéro.'),
            ),

            // ── Calcul ──
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: _valide
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Chaque membre paie',
                            style: theme.textTheme.bodyMedium),
                        Text('${fcfa(_parMembre)} ${_periodicites[_periodicite]!.toLowerCase()}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold, color: couleur)),
                        const SizedBox(height: 6),
                        Text('pendant $_periodes période${_periodes > 1 ? 's' : ''}, '
                            'soit ${fcfa(_parMembre * _periodes)} par membre.'),
                        Text('Total réuni : ${fcfa(_parMembre * _periodes * _membres)} '
                            'pour un prix de ${fcfa(p.prix)}.',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                      ],
                    )
                  : const Text('Indiquez 2 à 100 membres et 1 à 60 périodes.'),
            ),

            if (_erreur != null) ...[
              const SizedBox(height: 12),
              Text(_erreur!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: couleur,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _envoi || !_valide ? null : _creer,
              child: _envoi
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Créer l\'Adashé'),
            ),
            const SizedBox(height: 8),
            Text('Le vendeur doit accepter votre Adashé avant le début des cotisations. '
                'Le produit est livré quand le prix est réuni.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
