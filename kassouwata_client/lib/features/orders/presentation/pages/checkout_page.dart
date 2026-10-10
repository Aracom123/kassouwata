import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../paiement/data/paiement_models.dart';
import '../../domain/entities/order_entity.dart';
import '../bloc/order_bloc.dart';

enum TypeReglement { postpaye, prepaye }

// ─── Page principale ─────────────────────────────────────────────────────────

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _step = 0;

  // POSTPAYE : 4 étapes → Règlement → Paiement → Livraison → Résumé
  //            (paiement en ligne : écran de paiement après la confirmation)
  // PREPAYE  : 3 étapes → Règlement → Livraison → Résumé
  //            (chaque tranche est payée depuis le détail de la commande)
  int get _totalSteps => _typeReglement == TypeReglement.prepaye ? 3 : 4;

  // Étape 0 : type de règlement
  TypeReglement _typeReglement = TypeReglement.postpaye;

  // Étape 1 (POSTPAYE) : espèces à la livraison ou paiement en ligne
  PaymentMethod _paymentMethod = PaymentMethod.enLigne;

  // Étape adresse
  final _adresseCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  // Clés de formulaire pour la validation (4 max)
  final _formKeys = List.generate(4, (_) => GlobalKey<FormState>());

  @override
  void dispose() {
    _adresseCtrl.dispose();
    _villeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    return _formKeys[_step].currentState?.validate() ?? true;
  }

  void _next() {
    if (!_validateCurrentStep()) return;
    if (_step < _totalSteps - 1) setState(() => _step++);
  }

  void _previous() {
    if (_step > 0) setState(() => _step--);
  }

  void _onTypeReglementChanged(TypeReglement v) {
    setState(() {
      _typeReglement = v;
      // Revenir à l'étape 0 si on change de type après avoir avancé
      if (_step > 0) _step = 0;
    });
  }

  bool get _paiementEnLigne =>
      _typeReglement == TypeReglement.postpaye &&
      _paymentMethod == PaymentMethod.enLigne;

  /// Commande créée : paiement en ligne immédiat (post-payé « en ligne »),
  /// sinon retour à la liste des commandes.
  Future<void> _onCommandePassee(
      BuildContext context, List<OrderEntity> commandes) async {
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final orderBloc = context.read<OrderBloc>();
    context.read<CartBloc>().add(const ClearCart());

    final commande = commandes.isNotEmpty ? commandes.first : null;
    if (!_paiementEnLigne || commande == null) {
      router.go('/orders');
      messenger.showSnackBar(SnackBar(
        content: Text(_typeReglement == TypeReglement.prepaye
            ? 'Commande passée ! Réglez vos tranches depuis le détail de la commande.'
            : 'Commande passée avec succès !'),
        backgroundColor: Colors.green,
      ));
      return;
    }

    // L'écran de paiement s'ouvre par-dessus le checkout ; au retour on
    // bascule sur la liste des commandes, quel que soit le résultat.
    final issue = await router.push<IssuePaiement>(
      '/paiement',
      extra: PaiementArgs(
        typeOperation: TypeOperationPaiement.commande,
        operationId: commande.idCommande,
        montant: commande.montantTotal,
        titre: 'Commande #${commande.idCommande}',
        sousTitre: 'Paiement de votre commande',
      ),
    );

    orderBloc.add(const LoadOrders());
    router.go('/orders');
    final reussi = issue?.reussi ?? false;
    final enAttente = issue?.statut == StatutPaiement.enAttente;
    messenger.showSnackBar(SnackBar(
      content: Text(reussi
          ? 'Commande passée et payée avec succès !'
          : enAttente && issue?.referenceExterne != null
              ? 'Commande passée. Paiement en cours de confirmation…'
              : 'Commande enregistrée. Vous pourrez la payer depuis son détail.'),
      backgroundColor: reussi ? Colors.green : Colors.orange,
    ));
  }

  String get _adresseLivraison {
    final parts = [
      _adresseCtrl.text.trim(),
      _villeCtrl.text.trim(),
    ].where((s) => s.isNotEmpty).join(', ');
    final note = _noteCtrl.text.trim();
    return note.isNotEmpty ? '$parts — $note' : parts;
  }

  @override
  Widget build(BuildContext context) {
    final cartState = context.watch<CartBloc>().state;

    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state.status == OrderStatus2.placed) {
          _onCommandePassee(context, state.placedOrders);
        }
        if (state.status == OrderStatus2.failure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.errorMessage ?? 'Erreur lors de la commande'),
            backgroundColor: Colors.red,
          ));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Passer la commande'),
        ),
        body: Column(
          children: [
            // Indicateur de progression
            _StepIndicator(
              current: _step,
              total: _totalSteps,
              isPrepaye: _typeReglement == TypeReglement.prepaye,
            ),

            // Contenu de l'étape
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Form(
                  key: _formKeys[_step],
                  child: _buildStepContent(context, cartState),
                ),
              ),
            ),

            // Boutons navigation
            _buildNavBar(context, cartState),
          ],
        ),
      ),
    );
  }

  // ── Contenu selon l'étape ──────────────────────────────────────────────────
  // POSTPAYE : 0=Règlement, 1=Paiement, 2=Détails, 3=Livraison, 4=Résumé
  // PREPAYE  : 0=Règlement, 1=Livraison, 2=Résumé  (paiement au versement)

  Widget _buildStepContent(BuildContext context, CartState cartState) {
    final isPrepaye = _typeReglement == TypeReglement.prepaye;

    if (_step == 0) {
      return _StepTypeReglement(
        selected: _typeReglement,
        onChanged: _onTypeReglementChanged,
      );
    }

    if (isPrepaye) {
      switch (_step) {
        case 1:
          return _StepAdresse(
            adresseCtrl: _adresseCtrl,
            villeCtrl: _villeCtrl,
            noteCtrl: _noteCtrl,
          );
        case 2:
          return _StepResume(
            cartState: cartState,
            typeReglement: _typeReglement,
            paymentMethod: null,
            adresse: _adresseLivraison,
          );
        default:
          return const SizedBox.shrink();
      }
    } else {
      switch (_step) {
        case 1:
          return _StepMoyenPaiement(
            selected: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v),
          );
        case 2:
          return _StepAdresse(
            adresseCtrl: _adresseCtrl,
            villeCtrl: _villeCtrl,
            noteCtrl: _noteCtrl,
          );
        case 3:
          return _StepResume(
            cartState: cartState,
            typeReglement: _typeReglement,
            paymentMethod: _paymentMethod,
            adresse: _adresseLivraison,
          );
        default:
          return const SizedBox.shrink();
      }
    }
  }

  // ── Barre de navigation ────────────────────────────────────────────────────

  Widget _buildNavBar(BuildContext context, CartState cartState) {
    final isLast = _step == _totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))
        ],
      ),
      child: SafeArea(
        child: BlocBuilder<OrderBloc, OrderState>(
          builder: (context, orderState) {
            final placing = orderState.status == OrderStatus2.placing;
            return Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: placing ? null : _previous,
                      child: const Text('Précédent'),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: isLast
                      ? FilledButton(
                          onPressed:
                              placing || cartState.items.isEmpty
                                  ? null
                                  : () {
                                      context.read<OrderBloc>().add(PlaceOrder(
                                            items: cartState.items,
                                            // PREPAYE : moyen choisi à chaque tranche
                                            modePaiement: _typeReglement ==
                                                    TypeReglement.prepaye
                                                ? PaymentMethod.enLigne
                                                : _paymentMethod,
                                            typeVente: _typeReglement ==
                                                    TypeReglement.postpaye
                                                ? TypeVente.postpaye
                                                : TypeVente.prepaye,
                                            adresseLivraison:
                                                _adresseLivraison.isEmpty
                                                    ? null
                                                    : _adresseLivraison,
                                          ));
                                    },
                          child: placing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : Text(_paiementEnLigne
                                  ? 'Confirmer et payer'
                                  : 'Confirmer la commande'),
                        )
                      : FilledButton(
                          onPressed: _next,
                          child: const Text('Suivant'),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Indicateur d'étapes ─────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  final bool isPrepaye;

  List<String> get labels => isPrepaye
      ? const ['Règlement', 'Livraison', 'Résumé']
      : const ['Règlement', 'Paiement', 'Livraison', 'Résumé'];

  const _StepIndicator({
    required this.current,
    required this.total,
    this.isPrepaye = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: List.generate(total, (i) {
          final isDone = i < current;
          final isActive = i == current;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone || isActive
                              ? theme.colorScheme.primary
                              : Colors.grey.shade300,
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isActive
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 9,
                          color: isActive
                              ? theme.colorScheme.primary
                              : Colors.grey,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (i < total - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 18),
                      color: i < current
                          ? theme.colorScheme.primary
                          : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Étape 1 : Type de règlement ─────────────────────────────────────────────

class _StepTypeReglement extends StatelessWidget {
  final TypeReglement selected;
  final ValueChanged<TypeReglement> onChanged;

  const _StepTypeReglement(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Type de règlement',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
          'Choisissez comment vous souhaitez régler votre commande.',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        _ReglementCard(
          title: 'Post-payé',
          subtitle: 'Paiement en une seule fois : en ligne (Mobile Money, transfert ou carte) ou en espèces à la livraison.',
          icon: Icons.schedule_outlined,
          selected: selected == TypeReglement.postpaye,
          onTap: () => onChanged(TypeReglement.postpaye),
        ),
        const SizedBox(height: 12),
        _ReglementCard(
          title: 'Prépayé',
          subtitle: 'Paiement par tranches selon les conditions du vendeur. Chaque tranche se règle en ligne (Mobile Money, transfert ou carte).',
          icon: Icons.payments_outlined,
          selected: selected == TypeReglement.prepaye,
          onTap: () => onChanged(TypeReglement.prepaye),
        ),
      ],
    );
  }
}

class _ReglementCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ReglementCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                selected ? theme.colorScheme.primary : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          color: selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected
                    ? theme.colorScheme.primary
                    : Colors.grey,
                size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: selected
                              ? theme.colorScheme.primary
                              : null)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle,
                  color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

// ─── Étape 2 (POSTPAYE) : Mode de paiement ───────────────────────────────────

class _StepMoyenPaiement extends StatelessWidget {
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  const _StepMoyenPaiement({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mode de paiement',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
          'Payez maintenant en ligne, ou en espèces à la réception.',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        _ReglementCard(
          title: 'Paiement en ligne',
          subtitle:
              'Mobile Money, société de transfert ou carte bancaire (VISA, Mastercard). '
              'Le choix du moyen se fait juste après la confirmation.',
          icon: Icons.lock_outline,
          selected: selected == PaymentMethod.enLigne,
          onTap: () => onChanged(PaymentMethod.enLigne),
        ),
        const SizedBox(height: 12),
        _ReglementCard(
          title: 'Espèces à la livraison',
          subtitle: 'Payez en espèces lors de la réception. '
              'Veillez à préparer le montant exact.',
          icon: Icons.money_outlined,
          selected: selected == PaymentMethod.especes,
          onTap: () => onChanged(PaymentMethod.especes),
        ),
      ],
    );
  }
}

// ─── Étape : Adresse de livraison ──────────────────────────────────────────

class _StepAdresse extends StatelessWidget {
  final TextEditingController adresseCtrl;
  final TextEditingController villeCtrl;
  final TextEditingController noteCtrl;

  const _StepAdresse({
    required this.adresseCtrl,
    required this.villeCtrl,
    required this.noteCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Adresse de livraison',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Indiquez où vous souhaitez être livré.',
            style:
                theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
        const SizedBox(height: 24),
        TextFormField(
          controller: adresseCtrl,
          decoration: const InputDecoration(
            labelText: 'Adresse *',
            prefixIcon: Icon(Icons.location_on_outlined),
            hintText: 'Rue, quartier, bâtiment...',
          ),
          maxLines: 2,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'L\'adresse est obligatoire'
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: villeCtrl,
          decoration: const InputDecoration(
            labelText: 'Ville',
            prefixIcon: Icon(Icons.location_city_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: noteCtrl,
          decoration: const InputDecoration(
            labelText: 'Instructions pour le livreur (optionnel)',
            prefixIcon: Icon(Icons.note_outlined),
            hintText: 'Ex : sonner au 2ème étage...',
          ),
          maxLines: 2,
        ),
      ],
    );
  }
}

// ─── Étape finale : Résumé ────────────────────────────────────────────────────

class _StepResume extends StatelessWidget {
  final CartState cartState;
  final TypeReglement typeReglement;
  /// null pour PREPAYE : le moyen est choisi au moment de chaque versement.
  final PaymentMethod? paymentMethod;
  final String adresse;

  const _StepResume({
    required this.cartState,
    required this.typeReglement,
    required this.paymentMethod,
    required this.adresse,
  });

  String get _reglementLabel => typeReglement == TypeReglement.postpaye
      ? 'Post-payé (paiement en une fois)'
      : 'Prépayé (paiement par tranches)';

  String get _paiementLabel {
    if (paymentMethod == null) {
      return 'En ligne, lors de chaque versement';
    }
    switch (paymentMethod!) {
      case PaymentMethod.especes:
        return 'Espèces à la livraison';
      case PaymentMethod.enLigne:
        return 'En ligne — choix du moyen après confirmation';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.carte:
        return 'Carte bancaire';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Récapitulatif de la commande',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),

        // Articles
        _SummarySection(
          title: 'Articles',
          child: Column(
            children: [
              ...cartState.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.product.libelle} × ${item.quantity}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          '${item.subtotal.toStringAsFixed(0)} F',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    '${cartState.total.toStringAsFixed(0)} FCFA',
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Paiement
        _SummarySection(
          title: 'Paiement',
          child: Column(
            children: [
              _SummaryRow(
                  label: 'Type de règlement', value: _reglementLabel),
              const SizedBox(height: 6),
              _SummaryRow(label: 'Moyen', value: _paiementLabel),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Livraison
        _SummarySection(
          title: 'Livraison',
          child: _SummaryRow(
            label: 'Adresse',
            value: adresse.isEmpty ? 'Non renseignée' : adresse,
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'En confirmant, vous acceptez les conditions générales d\'utilisation de Kassouwata.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  final String title;
  final Widget child;
  const _SummarySection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary)),
            const Divider(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.grey)),
        ),
        Expanded(
          child: Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
