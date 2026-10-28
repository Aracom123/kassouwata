import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';

/// Mot de passe oublié : réinitialisation avec un code reçu par SMS.
///
/// Étape 1 : saisie du numéro → envoi du code (POST /api/nosUsers/forgot-password).
/// Étape 2 : code + nouveau mot de passe (POST /api/nosUsers/reset-password).
class ForgotPasswordPage extends StatefulWidget {
  /// Numéro déjà saisi sur l'écran de connexion (facultatif).
  final String? telephone;
  const ForgotPasswordPage({super.key, this.telephone});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final Dio _dio = getIt<DioClient>().dio;

  final _formTel = GlobalKey<FormState>();
  final _formReset = GlobalKey<FormState>();
  late final TextEditingController _telCtrl;
  final _codeCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();

  bool _codeEnvoye = false;
  bool _chargement = false;
  bool _masquer = true;
  String? _erreur;

  // Délai avant de pouvoir renvoyer un code
  Timer? _timer;
  int _attente = 0;

  @override
  void initState() {
    super.initState();
    _telCtrl = TextEditingController(text: widget.telephone ?? '');
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in [_telCtrl, _codeCtrl, _pwCtrl, _pw2Ctrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _demarrerCompteur(int secondes) {
    _timer?.cancel();
    setState(() => _attente = secondes);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _attente--);
      if (_attente <= 0) t.cancel();
    });
  }

  String _message(Object e, String parDefaut) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['error'] is String) return data['error'] as String;
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Connexion impossible. Vérifiez votre réseau.';
      }
    }
    return parDefaut;
  }

  Future<void> _envoyerCode() async {
    if (!(_formTel.currentState?.validate() ?? false)) return;
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      await _dio.post(ApiEndpoints.forgotPassword,
          data: {'telephone': _telCtrl.text.trim()});
      if (!mounted) return;
      setState(() => _codeEnvoye = true);
      _demarrerCompteur(60);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Code envoyé par SMS au ${_telCtrl.text.trim()}')));
    } catch (e) {
      if (!mounted) return;
      // 429 : un code a été envoyé il y a moins d'une minute
      final data = e is DioException ? e.response?.data : null;
      if (data is Map && data['attente'] is num) {
        setState(() => _codeEnvoye = true);
        _demarrerCompteur((data['attente'] as num).toInt());
      }
      setState(() => _erreur = _message(e, 'Impossible d\'envoyer le code.'));
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _reinitialiser() async {
    if (!(_formReset.currentState?.validate() ?? false)) return;
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      await _dio.post(ApiEndpoints.resetPassword, data: {
        'telephone': _telCtrl.text.trim(),
        'code': _codeCtrl.text.trim(),
        'password': _pwCtrl.text,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Mot de passe modifié. Vous pouvez vous connecter.'),
        backgroundColor: Colors.green,
      ));
      if (context.canPop()) {
        context.pop(_telCtrl.text.trim());
      } else {
        context.go('/login');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = _message(e, 'La réinitialisation a échoué.'));
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.lock_reset, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                _codeEnvoye
                    ? 'Saisissez le code reçu par SMS et choisissez un nouveau mot de passe.'
                    : 'Saisissez le numéro de téléphone de votre compte. '
                        'Nous vous enverrons un code par SMS.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formTel,
                child: TextFormField(
                  controller: _telCtrl,
                  enabled: !_codeEnvoye && !_chargement,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Numéro de téléphone',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Numéro requis';
                    if (v.trim().length != 8) return 'Le numéro doit contenir 8 chiffres';
                    return null;
                  },
                ),
              ),
              if (_codeEnvoye) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _chargement
                        ? null
                        : () => setState(() {
                              _codeEnvoye = false;
                              _erreur = null;
                              _codeCtrl.clear();
                            }),
                    child: const Text('Changer de numéro'),
                  ),
                ),
                Form(
                  key: _formReset,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _codeCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, letterSpacing: 8),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Code reçu par SMS',
                          border: OutlineInputBorder(),
                          counterText: '',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().length != 6) ? 'Le code contient 6 chiffres' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pwCtrl,
                        obscureText: _masquer,
                        decoration: InputDecoration(
                          labelText: 'Nouveau mot de passe',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_masquer
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () => setState(() => _masquer = !_masquer),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Mot de passe requis';
                          if (v.length < 6) return '6 caractères minimum';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pw2Ctrl,
                        obscureText: _masquer,
                        decoration: const InputDecoration(
                          labelText: 'Confirmer le mot de passe',
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v != _pwCtrl.text ? 'Les mots de passe ne correspondent pas' : null,
                      ),
                    ],
                  ),
                ),
              ],
              if (_erreur != null) ...[
                const SizedBox(height: 16),
                Text(_erreur!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _chargement ? null : (_codeEnvoye ? _reinitialiser : _envoyerCode),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _chargement
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_codeEnvoye ? 'Réinitialiser le mot de passe' : 'Recevoir le code'),
              ),
              if (_codeEnvoye) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: (_chargement || _attente > 0) ? null : _envoyerCode,
                  child: Text(_attente > 0
                      ? 'Renvoyer le code dans $_attente s'
                      : 'Je n\'ai pas reçu le code — Renvoyer'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
