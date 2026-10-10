import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth_bloc.dart';

class RegisterPage extends StatefulWidget {
  final String? redirectTo;
  const RegisterPage({super.key, this.redirectTo});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _telCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _telCtrl.dispose();
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(RegisterRequested(
          telephone: _telCtrl.text.trim(),
          password: _pwCtrl.text,
          nom: _nomCtrl.text.trim(),
          prenom: _prenomCtrl.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is OtpRequired) {
          context.push('/otp-verify', extra: {
            'telephone': state.telephone,
            'password': _pwCtrl.text,
          });
        } else if (state is Authenticated) {
          final dest = widget.redirectTo;
          if (dest != null) {
            context.go(dest);
          } else {
            context.go('/home');
          }
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.red,
          ));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Créer un compte')),
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
                      Text('Rejoignez Kassouwata',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Créez votre compte client gratuitement',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey)),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _nomCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nom *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _prenomCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Prénom *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _telCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Numéro de téléphone *',
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
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _pwCtrl,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe *',
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
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requis';
                          if (v.length < 6) return '6 caractères minimum';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _pw2Ctrl,
                        decoration: const InputDecoration(
                          labelText: 'Confirmer le mot de passe *',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: _obscure,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requis';
                          if (v != _pwCtrl.text) {
                            return 'Les mots de passe ne correspondent pas';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton(
                        onPressed: loading ? null : _submit,
                        child: loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Text('Créer mon compte'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Déjà un compte ? '),
                          TextButton(
                            onPressed: () => context.pop(),
                            child: const Text('Se connecter'),
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
