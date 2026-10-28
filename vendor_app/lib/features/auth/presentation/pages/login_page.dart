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
import '../../../../core/network/auth_navigator.dart';
import '../bloc/auth_bloc.dart';
import 'unauthorized_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (AuthNavigator.sessionExpired) {
      AuthNavigator.sessionExpired = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppSnackBar.showError(
          context,
          'Votre session a expiré. Veuillez vous reconnecter.',
        );
      });
    }
  }

  @override
  void dispose() {
    _telephoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>(),
      child: Scaffold(
        body: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is Authenticated) {
              if (state.user.status == UserStatus.kycPending) {
                context.go('/complete-profile', extra: {
                  'idUser': state.user.idUser,
                  'nom': '',
                  'prenom': state.user.personne?.prenom ?? '',
                });
              } else if (state.user.profile?.libelle.toUpperCase() !=
                  'VENDEUR') {
                showUnauthorizedModal(context,
                    telephone: state.user.telephone);
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
                      const SizedBox(height: 48),
                      const Icon(Icons.store_rounded, size: 48, color: AppColors.primary),
                      const SizedBox(height: 24),
                      const Text(
                        'Bienvenue !',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connectez-vous à votre espace vendeur',
                        style: TextStyle(fontSize: 16, color: AppColors.grey600),
                      ),
                      const SizedBox(height: 40),
                      CustomTextField(
                        label: 'Numéro de téléphone',
                        controller: _telephoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Numéro de téléphone requis';
                          if (v.length != 8) return 'Le numéro doit contenir exactement 8 chiffres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Mot de passe',
                        controller: _passwordController,
                        obscureText: true,
                        prefixIcon: Icons.lock_outline,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Mot de passe requis';
                          if (v.length < 6) return 'Minimum 6 caractères';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () async {
                            final tel = await context.push<String>(
                              '/forgot-password',
                              extra: _telephoneController.text.trim(),
                            );
                            if (tel != null && mounted) {
                              _telephoneController.text = tel;
                              _passwordController.clear();
                            }
                          },
                          child: const Text('Mot de passe oublié ?'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        label: 'Se connecter',
                        isLoading: state is AuthLoading,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            context.read<AuthBloc>().add(LoginRequested(
                                  telephone: _telephoneController.text.trim(),
                                  password: _passwordController.text,
                                ));
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Pas encore de compte ? "),
                          TextButton(
                            onPressed: () => context.go('/register'),
                            child: const Text('Créer un compte'),
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
}
