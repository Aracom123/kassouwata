import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../presentation/bloc/complete_profile_bloc.dart';

class CompleteProfilePage extends StatefulWidget {
  final String idUser;
  final String prenom;
  final String nom;

  const CompleteProfilePage({
    super.key,
    required this.idUser,
    required this.prenom,
    required this.nom,
  });

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Champs éditables
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _lieuNaissanceCtrl = TextEditingController();

  String? _genre;
  DateTime? _dateNaissance;

  static const _genres = ['Homme', 'Femme'];

  @override
  void initState() {
    super.initState();
    // Pré-remplir le nom s'il est disponible (lecture seule si non vide)
    if (widget.nom.isNotEmpty) {
      _nomCtrl.text = widget.nom;
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
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
    if (picked != null) {
      setState(() => _dateNaissance = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<CompleteProfileBloc>().add(SubmitProfile(
          idUser: widget.idUser,
          nom: _nomCtrl.text.trim(),
          prenom: widget.prenom,
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
    final prenomIsKnown = widget.prenom.isNotEmpty;
    final nomIsKnown = widget.nom.isNotEmpty;

    return BlocConsumer<CompleteProfileBloc, CompleteProfileState>(
      listener: (context, state) {
        if (state is CompleteProfileSuccess) {
          context.read<AuthBloc>().add(UserUpdated(state.user));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Profil complété ! Bienvenue sur Kassouwata.'),
            backgroundColor: Colors.green,
          ));
          context.go('/home');
        } else if (state is CompleteProfileSuccessNoRefresh) {
          context.read<AuthBloc>().add(const LogoutRequested());
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Profil complété ! Reconnectez-vous pour continuer.'),
            backgroundColor: Colors.green,
          ));
          context.go('/login');
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
            title: const Text('Compléter mon profil'),
            automaticallyImplyLeading: false,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // En-tête
                    Center(
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.person_outline,
                          size: 44,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      prenomIsKnown
                          ? 'Bonjour, ${widget.prenom} !'
                          : 'Bienvenue !',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complétez vos informations pour profiter pleinement de Kassouwata.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // ── Informations de base ──────────────────────────────
                    _SectionHeader(label: 'Informations personnelles'),
                    const SizedBox(height: 16),

                    // Prénom — lecture seule si connu
                    if (prenomIsKnown) ...[
                      _ReadOnlyField(
                        label: 'Prénom',
                        value: widget.prenom,
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Nom — lecture seule si connu, éditable sinon
                    if (nomIsKnown) ...[
                      _ReadOnlyField(
                        label: 'Nom',
                        value: widget.nom,
                        icon: Icons.person_outline,
                      ),
                    ] else ...[
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
                    ],
                    const SizedBox(height: 16),

                    // Email
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

                    // Genre
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

                    // ── Informations de naissance ──────────────────────────
                    _SectionHeader(label: 'Naissance'),
                    const SizedBox(height: 16),

                    // Date de naissance
                    InkWell(
                      onTap: isLoading ? null : _pickDate,
                      borderRadius: BorderRadius.circular(4),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date de naissance (optionnel)',
                          prefixIcon: Icon(Icons.cake_outlined),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _dateNaissance != null
                              ? DateFormat('dd/MM/yyyy').format(_dateNaissance!)
                              : 'Appuyer pour sélectionner',
                          style: TextStyle(
                            color: _dateNaissance != null
                                ? theme.textTheme.bodyLarge?.color
                                : Colors.grey[500],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lieu de naissance
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

                    // ── Adresse ────────────────────────────────────────────
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

                    // Bouton enregistrer
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Enregistrer mon profil',
                              style: TextStyle(fontSize: 16),
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

/// Widget pour afficher un champ en mode lecture seule
class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        suffixIcon: const Tooltip(
          message: 'Non modifiable',
          child: Icon(Icons.lock_outline, size: 18),
        ),
      ),
      child: Text(
        value,
        style: theme.textTheme.bodyLarge,
      ),
    );
  }
}

/// Séparateur de sections
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
