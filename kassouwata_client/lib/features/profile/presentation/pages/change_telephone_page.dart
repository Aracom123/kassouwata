import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// Changement du numéro de téléphone du compte.
///
/// Étape 1 : nouveau numéro + mot de passe → code envoyé par SMS au nouveau numéro.
/// Étape 2 : saisie du code → le numéro est changé partout (compte, tontines)
/// et la session est mise à jour avec le nouveau jeton.
class ChangeTelephonePage extends StatefulWidget {
  const ChangeTelephonePage({super.key});

  @override
  State<ChangeTelephonePage> createState() => _ChangeTelephonePageState();
}

class _ChangeTelephonePageState extends State<ChangeTelephonePage> {
  final Dio _dio = getIt<DioClient>().dio;

  final _formDemande = GlobalKey<FormState>();
  final _formCode = GlobalKey<FormState>();
  final _telCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  bool _codeEnvoye = false;
  bool _chargement = false;
  bool _masquer = true;
  String? _erreur;

  static const int _delaiRenvoi = 180; // 3 minutes
  Timer? _timer;
  int _attente = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _telCtrl.dispose();
    _pwCtrl.dispose();
    _codeCtrl.dispose();
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
    if (!_codeEnvoye && !(_formDemande.currentState?.validate() ?? false)) return;
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      await _dio.post(ApiEndpoints.changeTelephoneDemande, data: {
        'nouveauTelephone': _telCtrl.text.trim(),
        'motDePasse': _pwCtrl.text,
      });
      if (!mounted) return;
      setState(() => _codeEnvoye = true);
      _codeCtrl.clear();
      _demarrerCompteur(_delaiRenvoi);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Code envoyé par SMS au ${_telCtrl.text.trim()}')));
    } catch (e) {
      if (!mounted) return;
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

  Future<void> _confirmer() async {
    if (!(_formCode.currentState?.validate() ?? false)) return;
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final res = await _dio.post(ApiEndpoints.changeTelephoneConfirmation, data: {
        'nouveauTelephone': _telCtrl.text.trim(),
        'code': _codeCtrl.text.trim(),
      });
      final data = res.data as Map<String, dynamic>;
      final tel = data['telephone'] as String;
      final token = data['token'] as String;

      // Nouvelle session : l'ancien jeton était lié à l'ancien numéro
      final storage = getIt<SecureStorage>();
      await storage.saveToken(token);
      await storage.saveTelephone(tel);
      final exp = data['expiresIn'];
      if (exp is int) {
        await storage.saveExpiresIn(DateTime.fromMillisecondsSinceEpoch(exp));
      }

      if (!mounted) return;
      final bloc = context.read<AuthBloc>();
      final st = bloc.state;
      if (st is Authenticated) {
        final u = st.user;
        bloc.add(UserUpdated(UserEntity(
          idUser: u.idUser,
          telephone: tel,
          nom: u.nom,
          prenom: u.prenom,
          email: u.email,
          genre: u.genre,
          adresse: u.adresse,
          dateNaissance: u.dateNaissance,
          lieuNaissance: u.lieuNaissance,
          profile: u.profile,
          status: u.status,
          token: token,
        )));
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Votre numéro est maintenant le $tel.'),
        backgroundColor: Colors.green,
      ));
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = _message(e, 'Le changement de numéro a échoué.'));
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Changer de numéro')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.phonelink_setup, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                _codeEnvoye
                    ? 'Saisissez le code reçu par SMS sur votre nouveau numéro.'
                    : 'Vos achats, votre boutique et vos tontines restent attachés à votre compte. '
                        'Un code de confirmation sera envoyé au nouveau numéro.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formDemande,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _telCtrl,
                      enabled: !_codeEnvoye && !_chargement,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Nouveau numéro de téléphone',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Numéro requis';
                        if (v.trim().length != 8) return 'Le numéro doit contenir 8 chiffres';
                        return null;
                      },
                    ),
                    if (!_codeEnvoye) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pwCtrl,
                        obscureText: _masquer,
                        enabled: !_chargement,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe actuel',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_masquer
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () => setState(() => _masquer = !_masquer),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Mot de passe requis' : null,
                      ),
                    ],
                  ],
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
                    child: const Text('Modifier le numéro'),
                  ),
                ),
                Form(
                  key: _formCode,
                  child: TextFormField(
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
                    ),
                    validator: (v) =>
                        (v == null || v.trim().length != 6) ? 'Le code contient 6 chiffres' : null,
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
                onPressed: _chargement ? null : (_codeEnvoye ? _confirmer : _envoyerCode),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _chargement
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_codeEnvoye ? 'Confirmer le nouveau numéro' : 'Recevoir le code'),
              ),
              if (_codeEnvoye) ...[
                const SizedBox(height: 12),
                if (_attente > 0)
                  Text('Vous pourrez demander un nouveau code dans '
                      '${(_attente ~/ 60).toString().padLeft(2, '0')}:'
                      '${(_attente % 60).toString().padLeft(2, '0')}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey))
                else
                  OutlinedButton.icon(
                    onPressed: _chargement ? null : _envoyerCode,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Renvoyer le code'),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
