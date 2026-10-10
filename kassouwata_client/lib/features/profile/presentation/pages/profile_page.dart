import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/complete_profile_bloc.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          context.go('/home');
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! Authenticated) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return _ProfileView(user: state.user);
        },
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  final UserEntity user;
  const _ProfileView({required this.user});

  void _openEditPage(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authBloc),
          BlocProvider(create: (_) => getIt<CompleteProfileBloc>()),
        ],
        child: EditProfilePage(user: user),
      ),
    ));
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Avatar ────────────────────────────────────────────────────
          Center(
            child: CircleAvatar(
              radius: 52,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                user.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : '?',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              user.displayName,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Chip(
              label: Text(user.profile),
              backgroundColor: theme.colorScheme.secondaryContainer,
              labelStyle: TextStyle(
                color: theme.colorScheme.onSecondaryContainer,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Bouton Modifier ───────────────────────────────────────────
          FilledButton.tonalIcon(
            onPressed: () => _openEditPage(context),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Modifier mon profil'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 24),

          // ── Informations personnelles ─────────────────────────────────
          _SectionHeader(label: 'Informations personnelles'),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.phone_outlined,
                  label: 'Téléphone',
                  value: user.telephone,
                ),
                if (user.prenom != null || user.nom != null) ...[
                  const Divider(height: 1, indent: 56),
                  _InfoTile(
                    icon: Icons.person_outline,
                    label: 'Prénom',
                    value: user.prenom ?? '—',
                  ),
                  const Divider(height: 1, indent: 56),
                  _InfoTile(
                    icon: Icons.person_outline,
                    label: 'Nom',
                    value: user.nom ?? '—',
                  ),
                ],
                if (user.email != null) ...[
                  const Divider(height: 1, indent: 56),
                  _InfoTile(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user.email!,
                  ),
                ],
                if (user.genre != null) ...[
                  const Divider(height: 1, indent: 56),
                  _InfoTile(
                    icon: Icons.wc_outlined,
                    label: 'Genre',
                    value: user.genre!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Naissance ─────────────────────────────────────────────────
          if (user.dateNaissance != null || user.lieuNaissance != null) ...[
            _SectionHeader(label: 'Naissance'),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  if (user.dateNaissance != null)
                    _InfoTile(
                      icon: Icons.cake_outlined,
                      label: 'Date de naissance',
                      value: _formatDate(user.dateNaissance!),
                    ),
                  if (user.dateNaissance != null && user.lieuNaissance != null)
                    const Divider(height: 1, indent: 56),
                  if (user.lieuNaissance != null)
                    _InfoTile(
                      icon: Icons.location_city_outlined,
                      label: 'Lieu de naissance',
                      value: user.lieuNaissance!,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Adresse ───────────────────────────────────────────────────
          if (user.adresse != null) ...[
            _SectionHeader(label: 'Coordonnées'),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: _InfoTile(
                icon: Icons.home_outlined,
                label: 'Adresse',
                value: user.adresse!,
              ),
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      subtitle: Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }
}
