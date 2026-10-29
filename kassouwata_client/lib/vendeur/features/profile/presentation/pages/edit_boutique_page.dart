import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/di/injection.dart';
import '../../../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../../../features/onboarding/presentation/bloc/onboarding_bloc.dart';
import '../../../../features/shop/data/models/shop_model.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/location_picker_field.dart';
import '../../../../../espaces/espace_menu.dart';

class EditBoutiquePage extends StatefulWidget {
  const EditBoutiquePage({super.key});

  @override
  State<EditBoutiquePage> createState() => _EditBoutiquePageState();
}

class _EditBoutiquePageState extends State<EditBoutiquePage> {
  final _formKey = GlobalKey<FormState>();
  final _libelleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _adresseController = TextEditingController();

  ShopModel? _boutique;
  String? _idUser;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _libelleController.dispose();
    _descriptionController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final ds = getIt<AuthLocalDataSource>();
    final results = await Future.wait([ds.getCachedBoutique(), ds.getCachedUser()]);
    if (!mounted) return;
    final boutique = results[0] as ShopModel?;
    final user = results[1];
    setState(() {
      _boutique = boutique;
      _idUser = (user as dynamic)?.idUser as String?;
      _libelleController.text = boutique?.libelle ?? '';
      _descriptionController.text = boutique?.description ?? '';
      _adresseController.text = boutique?.adresse ?? '';
      _latitude = boutique?.latitude;
      _longitude = boutique?.longitude;
    });
  }

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
            leading: const BoutonMenu(),
            title: const Text(
              'Ma boutique',
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
              if (state is BoutiqueUpdated) {
                await _updateLocalCache();
                if (context.mounted) {
                  AppSnackBar.showSuccess(
                      context, 'Boutique mise à jour avec succès');
                  // Retourne true pour signaler à ProfilePage de recharger les données
                  if (context.canPop()) context.pop(true);
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
                      _buildIllustration(),
                      const SizedBox(height: 28),
                      _buildSectionLabel('Informations'),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'Nom de la boutique *',
                        controller: _libelleController,
                        prefixIcon: Icons.store_outlined,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Requis' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildDescriptionField(),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Adresse',
                        controller: _adresseController,
                        prefixIcon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: AppColors.grey200),
                      const SizedBox(height: 16),
                      LocationPickerField(
                        initialLatitude: _latitude,
                        initialLongitude: _longitude,
                        onLocationChanged: (LatLng? latLng) {
                          setState(() {
                            _latitude = latLng?.latitude;
                            _longitude = latLng?.longitude;
                          });
                        },
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

  Widget _buildIllustration() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        border:
            Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.storefront_rounded,
              size: 40, color: AppColors.secondary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _boutique?.libelle ?? 'Ma boutique',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Commission : ${_boutique?.commission.toStringAsFixed(1) ?? '—'}%',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.grey400),
                ),
              ],
            ),
          ),
        ],
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

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    final boutique = _boutique;
    final idUser = _idUser;
    if (boutique == null || idUser == null) return;

    context.read<OnboardingBloc>().add(EditBoutiqueRequested(
          idBoutique: boutique.idBoutique,
          idUser: idUser,
          libelle: _libelleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          adresse: _adresseController.text.trim().isEmpty
              ? null
              : _adresseController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          currentStatus: boutique.status.toJson(),
          currentCommission: boutique.commission,
        ));
  }

  Future<void> _updateLocalCache() async {
    final boutique = _boutique;
    if (boutique == null) return;
    final updated = ShopModel(
      idBoutique: boutique.idBoutique,
      libelle: _libelleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      adresse: _adresseController.text.trim().isEmpty
          ? null
          : _adresseController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      status: boutique.status,
      commission: boutique.commission,
    );
    await getIt<AuthLocalDataSource>().cacheBoutique(updated);
  }
}
