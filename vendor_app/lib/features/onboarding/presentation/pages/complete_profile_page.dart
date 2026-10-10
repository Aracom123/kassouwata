import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../bloc/onboarding_bloc.dart';

class CompleteProfilePage extends StatefulWidget {
  final String idUser;
  final String nom;
  final String prenom;

  const CompleteProfilePage({
    super.key,
    required this.idUser,
    required this.nom,
    required this.prenom,
  });

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomController;
  late final TextEditingController _prenomController;
  final _emailController = TextEditingController();
  final _adresseController = TextEditingController();
  final _lieuNaissanceController = TextEditingController();

  String _genre = 'Homme';
  DateTime? _dateNaissance;

  static const List<String> _genres = ['Homme', 'Femme', 'Autre'];

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.nom);
    _prenomController = TextEditingController(text: widget.prenom);
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    _lieuNaissanceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateNaissance ?? DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      helpText: 'Date de naissance',
    );
    if (picked != null) setState(() => _dateNaissance = picked);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OnboardingBloc>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocConsumer<OnboardingBloc, OnboardingState>(
          listener: (context, state) {
            if (state is ProfileCompleted) {
              context.go('/create-boutique', extra: {'idUser': widget.idUser});
            } else if (state is OnboardingFailure) {
              AppSnackBar.showError(context, state.message);
            }
            // SessionExpired : AuthNavigator.onUnauthorized redirige déjà
            // vers /login et LoginPage affiche le message d'expiration.
          },
          builder: (context, state) {
            return SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            _buildSectionTitle('Identité'),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    label: 'Prénom',
                                    controller: _prenomController,
                                    prefixIcon: Icons.person_outline,
                                    validator: (v) =>
                                        (v == null || v.isEmpty) ? 'Requis' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CustomTextField(
                                    label: 'Nom',
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
                            _buildDateNaissancePicker(),
                            const SizedBox(height: 24),
                            _buildSectionTitle('Coordonnées'),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: 'Adresse',
                              controller: _adresseController,
                              prefixIcon: Icons.location_on_outlined,
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Adresse requise' : null,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: 'Lieu de naissance',
                              controller: _lieuNaissanceController,
                              prefixIcon: Icons.place_outlined,
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Requis' : null,
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
                              label: 'Continuer',
                              isLoading: state is OnboardingLoading,
                              onPressed: () => _submit(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.grey200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Étape 1 sur 2',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.5,
              minHeight: 6,
              backgroundColor: AppColors.grey200,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Parle-nous de toi 👋',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ces informations permettront de valider ton compte.',
            style: TextStyle(fontSize: 14, color: AppColors.grey600),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
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
        Text(
          'Genre',
          style: TextStyle(fontSize: 14, color: AppColors.grey600),
        ),
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
                      color: selected
                          ? AppColors.primary
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.grey200,
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

  Widget _buildDateNaissancePicker() {
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
              color: _dateNaissance == null
                  ? AppColors.grey400
                  : AppColors.primary,
            ),
            const SizedBox(width: 12),
            Text(
              _dateNaissance == null
                  ? 'Date de naissance (optionnel)'
                  : _formatDate(_dateNaissance!),
              style: TextStyle(
                fontSize: 15,
                color: _dateNaissance == null
                    ? AppColors.grey400
                    : AppColors.grey900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<OnboardingBloc>().add(CompleteProfileRequested(
          idUser: widget.idUser,
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          genre: _genre,
          adresse: _adresseController.text.trim(),
          lieuNaissance: _lieuNaissanceController.text.trim(),
          dateNaissance: _dateNaissance,
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
        ));
  }
}