import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../bloc/auth_bloc.dart';

class OtpVerificationPage extends StatefulWidget {
  final String telephone;
  final String password;
  final String? prenom;
  final String? nom;

  const OtpVerificationPage({
    super.key,
    required this.telephone,
    required this.password,
    this.prenom,
    this.nom,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  // Compte à rebours pour le renvoi (30 minutes = 1800 s)
  int _secondsLeft = 1800;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 1800);
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

  String get _otpCode =>
      _controllers.map((c) => c.text).join();

  void _submit() {
    final code = _otpCode;
    if (code.length < 6) {
      AppSnackBar.showError(context, 'Veuillez saisir les 6 chiffres du code.');
      return;
    }
    context.read<AuthBloc>().add(OtpVerifyRequested(
          telephone: widget.telephone,
          code: code,
        ));
  }

  void _resend() {
    context
        .read<AuthBloc>()
        .add(ResendOtpRequested(telephone: widget.telephone));
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is OtpVerified) {
          // OTP OK → on connecte directement avec les identifiants
          context.read<AuthBloc>().add(LoginRequested(
                telephone: widget.telephone,
                password: widget.password,
              ));
        } else if (state is Authenticated) {
          if (state.user.status.name == 'kycPending' ||
              state.user.status.name == 'KYC_PENDING') {
            context.go('/complete-profile', extra: {
              'idUser': state.user.idUser,
              'nom': widget.nom ?? '',
              'prenom': widget.prenom ?? '',
            });
          } else {
            context.go('/dashboard');
          }
        } else if (state is AuthFailure) {
          AppSnackBar.showError(context, state.message);
          // Vider les cases OTP en cas d'erreur
          for (final c in _controllers) {
            c.clear();
          }
          _focusNodes.first.requestFocus();
        } else if (state is OtpRequired) {
          AppSnackBar.showSuccess(context, 'Nouveau code envoyé !');
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => context.go('/register'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_back_ios,
                            size: 16, color: AppColors.grey600),
                        const SizedBox(width: 4),
                        Text('Retour',
                            style: TextStyle(
                                fontSize: 14, color: AppColors.grey600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Icon(Icons.verified_outlined,
                      size: 52, color: AppColors.primary),
                  const SizedBox(height: 20),
                  Text(
                    'Vérification du numéro',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Un code à 6 chiffres a été envoyé au\n${widget.telephone}',
                    style: TextStyle(color: AppColors.grey600, fontSize: 15),
                  ),
                  const SizedBox(height: 36),

                  // Cases OTP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) => _buildOtpBox(i)),
                  ),

                  const SizedBox(height: 32),
                  CustomButton(
                    label: 'Vérifier',
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _submit,
                  ),
                  const SizedBox(height: 24),

                  // Compte à rebours + renvoi
                  Center(
                    child: _secondsLeft > 0
                        ? RichText(
                            text: TextSpan(
                              style: TextStyle(color: AppColors.grey600),
                              children: [
                                const TextSpan(text: 'Renvoyer le code dans '),
                                TextSpan(
                                  text: _timerLabel,
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                        : TextButton(
                            onPressed: isLoading ? null : _resend,
                            child: const Text('Renvoyer le code'),
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

  Widget _buildOtpBox(int index) {
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
            borderSide: BorderSide(color: AppColors.grey400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (val.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          // Soumettre automatiquement quand les 6 cases sont remplies
          if (_otpCode.length == 6) _submit();
        },
      ),
    );
  }
}
