import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/tontine_entity.dart';
import '../bloc/tontine_bloc.dart';

class _MemberOption {
  final String telephone;
  final String idUser;
  const _MemberOption({required this.telephone, required this.idUser});
}

class AddPeriodePage extends StatefulWidget {
  final TontineEntity tontine;
  final PeriodeVersementEntity? periode;
  final List<DemandeAdhesionEntity> members;

  const AddPeriodePage({
    super.key,
    required this.tontine,
    this.periode,
    this.members = const [],
  });

  @override
  State<AddPeriodePage> createState() => _AddPeriodePageState();
}

class _AddPeriodePageState extends State<AddPeriodePage> {
  final _formKey = GlobalKey<FormState>();
  final _libelleCtrl = TextEditingController();

  DateTime? _dateDebut;
  DateTime? _dateFin;

  List<_MemberOption> _memberOptions = [];
  bool _loadingMembers = false;
  _MemberOption? _selectedMember;

  bool get _isEditing => widget.periode != null;
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.periode!;
      _libelleCtrl.text = p.libelle;
      _dateDebut = p.dateDebut;
      _dateFin = p.dateFin;
    }
    _loadMemberIds();
  }

  @override
  void dispose() {
    _libelleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMemberIds() async {
    final accepted = widget.members
        .where((m) => m.statut == DemandeAdhesionStatus.acceptee)
        .toList();
    if (accepted.isEmpty) return;

    setState(() => _loadingMembers = true);
    try {
      final client = getIt<DioClient>();
      final results = await Future.wait(
        accepted.map((m) async {
          try {
            final resp =
                await client.dio.get(ApiEndpoints.userByTelephone(m.telephone));
            final idUser = resp.data?['idUser'] as String?;
            if (idUser != null) {
              return _MemberOption(telephone: m.telephone, idUser: idUser);
            }
          } catch (_) {}
          return null;
        }),
      );
      final options = results.whereType<_MemberOption>().toList();
      if (mounted) {
        setState(() {
          _memberOptions = options;
          if (_isEditing && widget.periode?.beneficiaireUserId != null) {
            _selectedMember = options
                .where((o) => o.idUser == widget.periode!.beneficiaireUserId)
                .firstOrNull;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  Future<void> _pickDate(bool isDebut) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isDebut ? _dateDebut : _dateFin) ?? DateTime.now(),
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

    if (_isEditing) {
      ctx.read<TontineBloc>().add(UpdatePeriode(
            idTontinePeriodeVersement:
                widget.periode!.idTontinePeriodeVersement,
            idTontine: widget.tontine.idTontine,
            libelle: _libelleCtrl.text.trim(),
            dateDebut: _dateDebut,
            dateFin: _dateFin,
            beneficiaireUserId: _selectedMember?.idUser,
          ));
    } else {
      ctx.read<TontineBloc>().add(CreatePeriode(
            idTontine: widget.tontine.idTontine,
            libelle: _libelleCtrl.text.trim(),
            dateDebut: _dateDebut,
            dateFin: _dateFin,
            beneficiaireUserId: _selectedMember?.idUser,
          ));
    }
  }

  void _confirmDelete(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Supprimer la période'),
        content: const Text(
            'Voulez-vous vraiment supprimer cette période ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ctx.read<TontineBloc>().add(DeletePeriode(
                    widget.periode!.idTontinePeriodeVersement,
                  ));
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
                  _isEditing ? 'Modifier la période' : 'Nouvelle période'),
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
                        // Bannière tontine parente
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.savings_outlined, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.tontine.libelle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(
                                '${widget.tontine.montant.toStringAsFixed(0)} F/membre',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _libelleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Libellé de la période *',
                            hintText: 'Ex: Période 1 - Avril 2026',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Champ requis'
                              : null,
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
                        const SizedBox(height: 16),
                        _buildBeneficiairePicker(context),
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
                          label: Text(
                              _isEditing ? 'Enregistrer' : 'Créer la période'),
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

  Widget _buildBeneficiairePicker(BuildContext context) {
    if (_loadingMembers) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Bénéficiaire',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.person_pin_outlined),
        ),
        child: SizedBox(
          height: 20,
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Chargement des membres…',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (_memberOptions.isEmpty) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Bénéficiaire',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.person_pin_outlined),
        ),
        child: Text(
          'Aucun membre accepté',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Autocomplete<_MemberOption>(
          initialValue: _selectedMember != null
              ? TextEditingValue(text: _selectedMember!.telephone)
              : null,
          optionsBuilder: (TextEditingValue value) {
            if (value.text.isEmpty) return _memberOptions;
            return _memberOptions
                .where((m) => m.telephone.contains(value.text));
          },
          displayStringForOption: (m) => m.telephone,
          onSelected: (m) => setState(() => _selectedMember = m),
          fieldViewBuilder: (ctx, textCtrl, focusNode, onSubmitted) {
            return TextFormField(
              controller: textCtrl,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Bénéficiaire',
                hintText: 'Rechercher un membre…',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_pin_outlined),
                suffixIcon: _selectedMember != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          textCtrl.clear();
                          setState(() => _selectedMember = null);
                        },
                      )
                    : null,
              ),
            );
          },
          optionsViewBuilder: (ctx, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (_, i) {
                      final m = options.elementAt(i);
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          child: Text(
                            m.telephone.isNotEmpty ? m.telephone[0] : '?',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(m.telephone),
                        onTap: () => onSelected(m),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        if (_selectedMember != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Sélectionné : ${_selectedMember!.telephone}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
      ],
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
              color: date != null ? null : Colors.grey.shade500),
        ),
      ),
    );
  }
}
