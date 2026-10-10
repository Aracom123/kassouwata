import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../../../features/auth/data/models/personne_model.dart';
import '../../../../features/auth/data/models/user_model.dart';
import '../../../../features/onboarding/presentation/bloc/onboarding_bloc.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _adresseController = TextEditingController();
  final _lieuNaissanceController = TextEditingController();

  String? _genre;
  DateTime? _dateNaissance;
  UserModel? _user;

  static const List<String> _genres = ['Homme', 'Femme', 'Autre'];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    _lieuNaissanceController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await getIt<AuthLocalDataSource>().getCachedUser();
    if (!mounted) return;
    final p = user?.personne;
    setState(() {
      _user = user;
      _prenomController.text = p?.prenom ?? '';
      _nomController.text = p?.nom ?? '';
      _emailController.text = p?.email ?? '';
      _adresseController.text = p?.adresse ?? '';
      _lieuNaissanceController.text = p?.lieuNaissance ?? '';
      _genre = (p?.genre?.isNotEmpty == true) ? p!.genre : null;
      _dateNaissance = p?.dateNaissance;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateNaissance ?? DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      helpText: 'Date de naissance',
    );
    if (picked != null) setState(() => _dateNaissance = picked);
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OnboardingBloc>(),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 18, color: AppColors.grey600),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              'Modifier mon profil',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ),
            centerTitle: true,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppColors.grey200),
            ),
          ),
          body: BlocConsumer<OnboardingBloc, OnboardingState>(
            listener: (context, state) async {
              if (state is ProfileUpdated) {
                // Mise à jour du cache local AVANT le pop, pour que
                // ProfilePage récupère immédiatement les nouvelles données
                await _updateLocalCache();
                if (context.mounted) {
                  AppSnackBar.showSuccess(context, 'Profil mis à jour avec succès');
                  // Retourne true pour indiquer à ProfilePage qu'un rechargement est nécessaire
                  context.pop(true);
                }
              } else if (state is OnboardingFailure) {
                AppSnackBar.showError(context, state.message);
              }
            },
            builder: (context, state) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatar(),
                      const SizedBox(height: 28),
                      _buildSectionLabel('Identité'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'Prénom *',
                              controller: _prenomController,
                              prefixIcon: Icons.person_outline,
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Requis' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              label: 'Nom *',
                              controller: _nomController,
                              prefixIcon: Icons.person_outline,
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Requis' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildGenreSelector(),
                      const SizedBox(height: 16),
                      _buildDatePicker(),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Lieu de naissance',
                        controller: _lieuNaissanceController,
                        prefixIcon: Icons.place_outlined,
                      ),
                      const SizedBox(height: 28),
                      _buildSectionLabel('Coordonnées'),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'Adresse',
                        controller: _adresseController,
                        prefixIcon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Email (optionnel)',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        label: 'Enregistrer les modifications',
                        isLoading: state is OnboardingLoading,
                        onPressed: () => _submit(context),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final prenom = _prenomController.text;
    final nom = _nomController.text;
    final p = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final n = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    final initials = '$p$n'.isNotEmpty ? '$p$n' : '?';

    return Center(
      child: CircleAvatar(
        radius: 36,
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.grey400,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildGenreSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Genre', style: TextStyle(fontSize: 14, color: AppColors.grey600)),
        const SizedBox(height: 8),
        Row(
          children: _genres.map((g) {
            final selected = _genre == g;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: g != _genres.last ? 8 : 0),
                child: GestureDetector(
                  onTap: () => setState(() => _genre = g),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.grey200,
                      ),
                    ),
                    child: Text(
                      g,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: selected ? Colors.white : AppColors.grey600,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _dateNaissance == null ? AppColors.grey200 : AppColors.primary,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: _dateNaissance == null ? AppColors.grey400 : AppColors.primary,
            ),
            const SizedBox(width: 12),
            Text(
              _dateNaissance == null
                  ? 'Date de naissance (optionnel)'
                  : _formatDate(_dateNaissance!),
              style: TextStyle(
                fontSize: 15,
                color: _dateNaissance == null ? AppColors.grey400 : AppColors.grey900,
              ),
            ),
            if (_dateNaissance != null) ...[
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _dateNaissance = null),
                child: const Icon(Icons.close, size: 16, color: AppColors.grey400),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    final user = _user;
    if (user == null) return;

    context.read<OnboardingBloc>().add(EditProfileRequested(
          idUser: user.idUser,
          currentStatus: user.status.toJson(),
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          genre: _genre,
          adresse: _adresseController.text.trim().isEmpty
              ? null
              : _adresseController.text.trim(),
          lieuNaissance: _lieuNaissanceController.text.trim().isEmpty
              ? null
              : _lieuNaissanceController.text.trim(),
          dateNaissance: _dateNaissance,
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
        ));
  }

  Future<void> _updateLocalCache() async {
    final user = _user;
    if (user == null) return;
    final ds = getIt<AuthLocalDataSource>();
    final oldPersonne = user.personne;
    final updatedPersonne = PersonneModel(
      idPersonne: oldPersonne?.idPersonne ?? '',
      nom: _nomController.text.trim(),
      prenom: _prenomController.text.trim(),
      genre: _genre,
      adresse: _adresseController.text.trim().isEmpty
          ? null
          : _adresseController.text.trim(),
      lieuNaissance: _lieuNaissanceController.text.trim().isEmpty
          ? null
          : _lieuNaissanceController.text.trim(),
      dateNaissance: _dateNaissance,
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      photo: oldPersonne?.photo,
    );
    final updatedUser = UserModel(
      idUser: user.idUser,
      telephone: user.telephone,
      status: user.status,
      profile: user.profile,
      personne: updatedPersonne,
    );
    await ds.cacheUser(updatedUser);
  }
}
