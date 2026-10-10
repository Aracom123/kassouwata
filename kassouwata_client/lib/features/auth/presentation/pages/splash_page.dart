import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const CheckAuthStatus());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is KycPending) {
          context.go('/complete-profile', extra: {
            'idUser': state.idUser,
            'prenom': state.prenom ?? '',
            'nom': state.nom ?? '',
          });
        } else if (state is Authenticated) {
          context.go('/home');
        } else if (state is Unauthenticated) {
          context.go('/home'); // catalogue accessible sans auth
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.storefront_rounded,
                  size: 80, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                'Kassouwata',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text('Le marché dans votre poche',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14)),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
