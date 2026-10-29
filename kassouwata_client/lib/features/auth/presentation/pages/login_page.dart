import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../vendeur/vendeur_session.dart';
import '../../../../espaces/espace_auth.dart';
import '../../../../espaces/espace.dart';

class LoginPage extends StatefulWidget {
  /// Si non null, on redirige vers cette page après connexion
  final String? redirectTo;
  const LoginPage({super.key, this.redirectTo});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _telCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _telCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(LoginRequested(
          telephone: _telCtrl.text.trim(),
          password: _pwCtrl.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final espace = espaceVise(widget.redirectTo);
    final couleur = espace.couleur(context);
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is KycPending) {
          context.go('/complete-profile', extra: {
            'idUser': state.idUser,
            'prenom': state.prenom ?? '',
            'nom': state.nom ?? '',
          });
          return;
        }
        if (state is Authenticated) {
          final dest = widget.redirectTo;
          if (dest != null &&
              dest.startsWith('/vendeur') &&
              !VendeurSession.estVendeur(state.user.profile)) {
            // Compte Client : on l'emmène dans l'espace Acheteur
            EspaceService.memoriser(Espace.acheteur);
            context.go(Espace.acheteur.accueil);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Vous êtes connecté avec un compte Client : '
                  'bienvenue dans l\'espace Acheteur. Pour vendre, ouvrez '
                  'l\'espace Vendeur et créez votre boutique.'),
              duration: Duration(seconds: 5),
            ));
          } else if (dest != null) {
            context.go(dest);
          } else {
            _allerAccueil(context);
          }
        }
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.red,
          ));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Connexion · ${espace.nom}')),
        body: SafeArea(
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final loading = state is AuthLoading;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      EnteteAuth(
                        espace: espace,
                        titre: 'Connexion',
                        sousTitre: espace.accroche,
                      ),
                      TextFormField(
                        controller: _telCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Numéro de téléphone',
                          hintText: '+22790000000',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requis';
                          if (v.trim().length != 8) return 'Le numéro doit contenir exactement 8 chiffres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pwCtrl,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        obscureText: _obscure,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Requis' : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () async {
                            final tel = await context.push<String>(
                              '/forgot-password',
                              extra: _telCtrl.text.trim(),
                            );
                            if (tel != null && mounted) {
                              _telCtrl.text = tel;
                              _pwCtrl.clear();
                            }
                          },
                          child: const Text('Mot de passe oublié ?'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: couleur,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: loading ? null : _submit,
                        child: loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Text('Se connecter'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Pas encore de compte ? "),
                          TextButton(
                            onPressed: () => context.push('/register',
                                extra: widget.redirectTo),
                            child: const Text('Créer un compte'),
                          ),
                        ],
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
}

/// Accueil après connexion : un vendeur sans boutique est invité à la créer.
Future<void> _allerAccueil(BuildContext context) async {
  final dest = await getIt<VendeurSession>().accueilApresConnexion();
  if (context.mounted) context.go(dest);
}
