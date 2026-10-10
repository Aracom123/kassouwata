import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/complete_profile_bloc.dart';

class EditProfilePage extends StatefulWidget {
  final UserEntity user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomCtrl;
  late final TextEditingController _prenomCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _adresseCtrl;
  late final TextEditingController _lieuNaissanceCtrl;

  String? _genre;
  DateTime? _dateNaissance;

  static const _genres = ['Homme', 'Femme'];

  @override
  void initState() {
    super.initState();
    _nomCtrl = TextEditingController(text: widget.user.nom ?? '');
    _prenomCtrl = TextEditingController(text: widget.user.prenom ?? '');
    _emailCtrl = TextEditingController(text: widget.user.email ?? '');
    _adresseCtrl = TextEditingController(text: widget.user.adresse ?? '');
    _lieuNaissanceCtrl = TextEditingController(text: widget.user.lieuNaissance ?? '');
    _genre = widget.user.genre;
    if (widget.user.dateNaissance != null) {
      _dateNaissance = DateTime.tryParse(widget.user.dateNaissance!);
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _adresseCtrl.dispose();
    _lieuNaissanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateNaissance ?? DateTime(now.year - 20),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 5),
      helpText: 'Date de naissance',
    );
    if (picked != null) setState(() => _dateNaissance = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<CompleteProfileBloc>().add(UpdateProfile(
          idUser: widget.user.idUser,
          nom: _nomCtrl.text.trim(),
          prenom: _prenomCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          genre: _genre,
          adresse: _adresseCtrl.text.trim().isEmpty ? null : _adresseCtrl.text.trim(),
          dateNaissance: _dateNaissance != null
              ? DateFormat('yyyy-MM-dd').format(_dateNaissance!)
              : null,
          lieuNaissance: _lieuNaissanceCtrl.text.trim().isEmpty
              ? null
              : _lieuNaissanceCtrl.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<CompleteProfileBloc, CompleteProfileState>(
      listener: (context, state) {
        if (state is UpdateProfileSuccess) {
          // Mettre à jour l'AuthBloc directement avec le UserEntity rafraîchi
          context.read<AuthBloc>().add(UserUpdated(state.user));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Profil mis à jour avec succès.'),
            backgroundColor: Colors.green,
          ));
          Navigator.of(context).pop();
        } else if (state is CompleteProfileFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.red,
          ));
        }
      },
      builder: (context, state) {
        final isLoading = state is CompleteProfileLoading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Modifier mon profil'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Identité ─────────────────────────────────────────
                    _SectionHeader(label: 'Identité'),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _prenomCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Prénom *',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nomCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nom *',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Adresse e-mail (optionnel)',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!emailRegex.hasMatch(v.trim())) {
                          return 'Adresse e-mail invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _genre,
                      decoration: const InputDecoration(
                        labelText: 'Genre (optionnel)',
                        prefixIcon: Icon(Icons.wc_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: _genres
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) => setState(() => _genre = v),
                    ),
                    const SizedBox(height: 32),

                    // ── Naissance ─────────────────────────────────────────
                    _SectionHeader(label: 'Naissance'),
                    const SizedBox(height: 16),

                    InkWell(
                      onTap: isLoading ? null : _pickDate,
                      borderRadius: BorderRadius.circular(4),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date de naissance (optionnel)',
                          prefixIcon: Icon(Icons.cake_outlined),
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _dateNaissance != null
                                  ? DateFormat('dd/MM/yyyy').format(_dateNaissance!)
                                  : 'Appuyer pour sélectionner',
                              style: TextStyle(
                                color: _dateNaissance != null
                                    ? theme.textTheme.bodyLarge?.color
                                    : Colors.grey[500],
                              ),
                            ),
                            if (_dateNaissance != null)
                              GestureDetector(
                                onTap: () => setState(() => _dateNaissance = null),
                                child: Icon(Icons.clear, size: 18, color: Colors.grey[500]),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _lieuNaissanceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Lieu de naissance (optionnel)',
                        prefixIcon: Icon(Icons.location_city_outlined),
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 32),

                    // ── Coordonnées ───────────────────────────────────────
                    _SectionHeader(label: 'Coordonnées'),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _adresseCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Adresse (optionnel)',
                        prefixIcon: Icon(Icons.home_outlined),
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 32),

                    FilledButton.icon(
                      onPressed: isLoading ? null : _submit,
                      icon: isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Enregistrer les modifications',
                          style: TextStyle(fontSize: 16)),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
        ),
      ],
    );
  }
}
