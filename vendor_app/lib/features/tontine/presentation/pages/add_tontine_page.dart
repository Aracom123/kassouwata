import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../domain/entities/tontine_entity.dart';
import '../bloc/tontine_bloc.dart';

const _periodicites = [
  'QUOTIDIENNE',
  'HEBDOMADAIRE',
  'MENSUELLE',
  'TRIMESTRIELLE',
  'SEMESTRIELLE',
  'ANNUELLE',
];

class AddTontinePage extends StatefulWidget {
  final TontineEntity? tontine;
  const AddTontinePage({super.key, this.tontine});

  @override
  State<AddTontinePage> createState() => _AddTontinePageState();
}

class _AddTontinePageState extends State<AddTontinePage> {
  final _formKey = GlobalKey<FormState>();
  final _libelleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();

  DateTime? _dateDebut;
  DateTime? _dateFin;
  String? _periodicite;
  String? _ownerIdUser;

  bool get _isEditing => widget.tontine != null;
  final _dateFormat = DateFormat('dd/MM/yyyy');

  Future<void> _loadOwner() async {
    final user = await getIt<AuthLocalDataSource>().getCachedUser();
    if (mounted) setState(() => _ownerIdUser = user?.idUser);
  }

  @override
  void initState() {
    super.initState();
    _loadOwner();
    if (_isEditing) {
      final t = widget.tontine!;
      _libelleCtrl.text = t.libelle;
      _descriptionCtrl.text = t.description ?? '';
      _montantCtrl.text = t.montant.toStringAsFixed(0);
      _dateDebut = t.dateDebut;
      _dateFin = t.dateFin;
      _periodicite = t.periodicite;
    }
  }

  @override
  void dispose() {
    _libelleCtrl.dispose();
    _descriptionCtrl.dispose();
    _montantCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isDebut) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isDebut ? _dateDebut : _dateFin) ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isDebut) {
          _dateDebut = picked;
        } else {
          _dateFin = picked;
        }
      });
    }
  }

  void _submit(BuildContext ctx) {
    if (!_formKey.currentState!.validate()) return;

    final montant =
        double.tryParse(_montantCtrl.text.replaceAll(',', '.')) ?? 0;

    if (_isEditing) {
      ctx.read<TontineBloc>().add(UpdateTontine(
            idTontine: widget.tontine!.idTontine,
            libelle: _libelleCtrl.text.trim(),
            description: _descriptionCtrl.text.trim(),
            dateDebut: _dateDebut,
            dateFin: _dateFin,
            montant: montant,
            periodicite: _periodicite,
          ));
    } else {
      ctx.read<TontineBloc>().add(CreateTontine(
            libelle: _libelleCtrl.text.trim(),
            description: _descriptionCtrl.text.trim(),
            dateDebut: _dateDebut,
            dateFin: _dateFin,
            montant: montant,
            periodicite: _periodicite,
            ownerIdUser: _ownerIdUser,
          ));
    }
  }

  void _confirmDelete(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Supprimer la tontine'),
        content: const Text(
            'Voulez-vous vraiment supprimer cette tontine ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ctx
                  .read<TontineBloc>()
                  .add(DeleteTontine(widget.tontine!.idTontine));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
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
              title: Text(
                  _isEditing ? 'Modifier la tontine' : 'Nouvelle tontine'),
              actions: _isEditing
                  ? [
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        tooltip: 'Supprimer',
                        onPressed: () => _confirmDelete(ctx),
                      ),
                    ]
                  : null,
            ),
            body: BlocBuilder<TontineBloc, TontineState>(
              builder: (context, state) {
                final isLoading = state is TontineLoading;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _libelleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nom de la tontine *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Champ requis'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _montantCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Cotisation par membre (F) *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requis';
                            if (double.tryParse(v.replaceAll(',', '.')) ==
                                null) {
                              return 'Montant invalide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _periodicite,
                          decoration: const InputDecoration(
                            labelText: 'Périodicité',
                            border: OutlineInputBorder(),
                          ),
                          items: _periodicites
                              .map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _periodicite = v),
                          hint: const Text('Sélectionner'),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                                child: _buildDateField(
                                    'Date de début', _dateDebut, true)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildDateField(
                                    'Date de fin', _dateFin, false)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : () => _submit(ctx),
                          icon: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : Icon(_isEditing ? Icons.save : Icons.add),
                          label: Text(_isEditing
                              ? 'Enregistrer'
                              : 'Créer la tontine'),
                          style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, bool isDebut) {
    return InkWell(
      onTap: () => _pickDate(isDebut),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (date != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() {
                    if (isDebut) {
                      _dateDebut = null;
                    } else {
                      _dateFin = null;
                    }
                  }),
                ),
              const Icon(Icons.calendar_today_outlined, size: 18),
              const SizedBox(width: 4),
            ],
          ),
        ),
        child: Text(
          date != null ? _dateFormat.format(date) : '—',
          style: TextStyle(
            color: date != null ? null : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}
