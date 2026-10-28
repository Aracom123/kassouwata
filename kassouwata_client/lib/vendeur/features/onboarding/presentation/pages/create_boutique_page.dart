import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/location_picker_field.dart';
import '../bloc/onboarding_bloc.dart';

class CreateBoutiquePage extends StatefulWidget {
  final String idUser;

  const CreateBoutiquePage({super.key, required this.idUser});

  @override
  State<CreateBoutiquePage> createState() => _CreateBoutiquePageState();
}

class _CreateBoutiquePageState extends State<CreateBoutiquePage> {
  final _formKey = GlobalKey<FormState>();
  final _libelleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _adresseController = TextEditingController();

  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _libelleController.dispose();
    _descriptionController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OnboardingBloc>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocConsumer<OnboardingBloc, OnboardingState>(
          listener: (context, state) {
            if (state is BoutiqueCreated) {
              // Ouverte depuis « Ma boutique » : on y revient ; sinon (après
              // inscription) on ouvre l'onglet.
              if (context.canPop()) {
                context.pop(true);
              } else {
                context.go('/ma-boutique');
              }
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
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildIllustration(),
                            const SizedBox(height: 32),
                            CustomTextField(
                              label: 'Nom de la boutique *',
                              controller: _libelleController,
                              prefixIcon: Icons.store_outlined,
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Le nom est requis'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _buildDescriptionField(),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: 'Adresse de la boutique',
                              controller: _adresseController,
                              prefixIcon: Icons.location_on_outlined,
                            ),
                            const SizedBox(height: 24),
                            const Divider(color: AppColors.grey200),
                            const SizedBox(height: 16),
                            LocationPickerField(
                              onLocationChanged: (LatLng? latLng) {
                                setState(() {
                                  _latitude = latLng?.latitude;
                                  _longitude = latLng?.longitude;
                                });
                              },
                            ),
                            const SizedBox(height: 32),
                            CustomButton(
                              label: 'Créer ma boutique 🚀',
                              isLoading: state is OnboardingLoading,
                              onPressed: () => _submit(context),
                            ),
                            const SizedBox(height: 12),
                            _buildSkipButton(context),
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

  Widget _buildHeader() {
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Étape 2 sur 2',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 1.0,
              minHeight: 6,
              backgroundColor: AppColors.grey200,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Crée ta boutique 🏪',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lance-toi ! Tu pourras modifier ces informations plus tard.',
            style: TextStyle(fontSize: 14, color: AppColors.grey600),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.storefront_rounded, size: 56, color: AppColors.secondary),
          const SizedBox(height: 12),
          const Text(
            'Votre espace vendeur',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gérez vos produits, commandes\net suivez vos ventes.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.grey600),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Description (optionnel)',
        alignLabelWithHint: true,
        prefixIcon: const Padding(
          padding: EdgeInsets.only(bottom: 40),
          child: Icon(Icons.description_outlined),
        ),
        filled: true,
        fillColor: AppColors.grey50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildSkipButton(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () =>
            context.canPop() ? context.pop() : context.go('/home'),
        child: Text(
          'Passer pour l\'instant',
          style: TextStyle(color: AppColors.grey400, fontSize: 14),
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<OnboardingBloc>().add(CreateBoutiqueRequested(
          idUser: widget.idUser,
          libelle: _libelleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          adresse: _adresseController.text.trim().isEmpty
              ? null
              : _adresseController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
        ));
  }
}