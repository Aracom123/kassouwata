import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../vendeur/vendeur_session.dart';

class OtpVerificationPage extends StatefulWidget {
  final String telephone;
  final String password;

  const OtpVerificationPage({
    super.key,
    required this.telephone,
    required this.password,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  /// Délai avant de pouvoir redemander un code (le code reste valable 30 min).
  static const int _delaiRenvoi = 180; // 3 minutes
  int _secondsLeft = _delaiRenvoi;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _delaiRenvoi);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 0) {
        _timer?.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _timerLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  void _submit() {
    final code = _otpCode;
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez saisir les 6 chiffres du code.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    context.read<AuthBloc>().add(OtpVerifyRequested(
          telephone: widget.telephone,
          code: code,
        ));
  }

  void _resend() {
    for (final c in _controllers) {
      c.clear();
    }
    // Le compte à rebours repart quand le serveur confirme l'envoi (OtpRequired)
    context
        .read<AuthBloc>()
        .add(ResendOtpRequested(telephone: widget.telephone));
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is OtpVerified) {
          // OTP validé → rediriger vers la page de connexion
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Numéro vérifié ! Connectez-vous pour continuer.'),
            backgroundColor: Colors.green,
          ));
          context.go('/login');
        } else if (state is Authenticated) {
          _allerAccueil(context);
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.red,
          ));
          for (final c in _controllers) c.clear();
          _focusNodes.first.requestFocus();
        } else if (state is OtpRequired) {
          _startTimer();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Nouveau code envoyé !'),
            backgroundColor: Colors.green,
          ));
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return Scaffold(
          appBar: AppBar(title: const Text('Vérification')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Icon(Icons.verified_outlined, size: 52, color: primary),
                  const SizedBox(height: 20),
                  Text(
                    'Confirmez votre numéro',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Un code à 6 chiffres a été envoyé au\n${widget.telephone}',
                    style: const TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                  const SizedBox(height: 36),

                  // Cases OTP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) => _buildOtpBox(i, primary)),
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Vérifier'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Compte à rebours (3 min) puis bouton de renvoi
                  Center(
                    child: _secondsLeft > 0
                        ? RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(color: Colors.grey),
                              children: [
                                const TextSpan(
                                    text: 'Vous pourrez demander un nouveau code dans '),
                                TextSpan(
                                  text: _timerLabel,
                                  style: TextStyle(
                                      color: primary,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              const Text(
                                'Vous n\'avez pas reçu le code ?',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: isLoading ? null : _resend,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Renvoyer le code'),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOtpBox(int index, Color primary) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primary, width: 2),
          ),
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (val.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          if (_otpCode.length == 6) _submit();
        },
      ),
    );
  }
}

/// Accueil après connexion : un vendeur sans boutique est invité à la créer.
Future<void> _allerAccueil(BuildContext context) async {
  final dest = await getIt<VendeurSession>().accueilApresConnexion();
  if (context.mounted) context.go(dest);
}
