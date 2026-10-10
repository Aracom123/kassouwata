import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../shared/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';

Future<void> showUnauthorizedModal(
  BuildContext context, {
  String? telephone,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BlocProvider(
      create: (_) => getIt<AuthBloc>(),
      child: _UnauthorizedModal(telephone: telephone),
    ),
  );
}

class _UnauthorizedModal extends StatelessWidget {
  final String? telephone;
  const _UnauthorizedModal({this.telephone});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.of(context).pop();
          context.go('/login');
        }
      },
      child: PopScope(
        canPop: false,
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 44,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Accès non autorisé',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Votre compte ne dispose pas des autorisations nécessaires '
                  'pour accéder à l\'espace vendeur Kassouwata.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.grey600,
                        height: 1.5,
                      ),
                ),
                if (telephone != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 14, color: AppColors.grey400),
                        const SizedBox(width: 6),
                        Text(
                          telephone!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final loading = state is AuthLoading;
                    return SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: loading
                            ? null
                            : () => context
                                .read<AuthBloc>()
                                .add(LogoutRequested()),
                        icon: loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.logout_rounded),
                        label: Text(
                            loading ? 'Déconnexion...' : 'Se déconnecter'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'Contactez l\'administrateur pour obtenir les droits vendeur.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.grey400),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
