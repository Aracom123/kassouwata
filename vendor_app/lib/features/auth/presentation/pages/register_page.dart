import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/enums/user_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../bloc/auth_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is OtpRequired) {
              context.go('/otp-verify', extra: {
                'telephone': state.telephone,
                'password': _passwordController.text,
                'prenom': _prenomController.text.trim(),
                'nom': _nomController.text.trim(),
              });
            } else if (state is Authenticated) {
              if (state.user.status == UserStatus.kycPending) {
                context.go('/complete-profile', extra: {
                  'idUser': state.user.idUser,
                  'nom': _nomController.text.trim(),
                  'prenom': _prenomController.text.trim(),
                });
              } else {
                context.go('/dashboard');
              }
            } else if (state is AuthFailure) {
              AppSnackBar.showError(context, state.message);
            }
          },
          builder: (context, state) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildBackButton(context),
                      const SizedBox(height: 24),
                      _buildHeader(),
                      const SizedBox(height: 32),
                      CustomTextField(
                        label: 'Prénom *',
                        controller: _prenomController,
                        prefixIcon: Icons.person_outline,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Requis' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Nom *',
                        controller: _nomController,
                        prefixIcon: Icons.person_outline,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Requis' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Numéro de téléphone *',
                        controller: _telephoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Téléphone requis';
                          if (v.length != 8) return 'Le numéro doit contenir exactement 8 chiffres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Mot de passe *',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        prefixIcon: Icons.lock_outline,
                        suffixWidget: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Mot de passe requis';
                          if (v.length < 6) return 'Minimum 6 caractères';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Confirmer le mot de passe *',
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        prefixIcon: Icons.lock_outline,
                        suffixWidget: IconButton(
                          icon: Icon(_obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        validator: (v) {
                          if (v != _passwordController.text) {
                            return 'Les mots de passe ne correspondent pas';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        label: 'Créer mon compte',
                        isLoading: state is AuthLoading,
                        onPressed: () => _submit(context),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Déjà un compte ? '),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('Se connecter'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/login'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_back_ios, size: 16, color: AppColors.grey600),
          const SizedBox(width: 4),
          Text('Retour',
              style: TextStyle(fontSize: 14, color: AppColors.grey600)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.store_rounded, size: 44, color: AppColors.primary),
        const SizedBox(height: 16),
        const Text(
          'Créer un compte vendeur',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.grey900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Rejoignez notre réseau de vendeurs\net développez votre activité.',
          style: TextStyle(fontSize: 15, color: AppColors.grey600),
        ),
      ],
    );
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(RegisterRequested(
          telephone: _telephoneController.text.trim(),
          password: _passwordController.text,
          prenom: _prenomController.text.trim(),
          nom: _nomController.text.trim(),
        ));
  }
}