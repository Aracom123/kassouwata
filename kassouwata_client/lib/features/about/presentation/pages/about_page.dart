import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('À propos')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Logo / identité
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.storefront_rounded,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'KASUWATA My Buz',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              'Le marché dans votre poche',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Chip(
              label: const Text('Version 1.0.0'),
              backgroundColor: theme.colorScheme.secondaryContainer,
              labelStyle: TextStyle(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontSize: 12),
            ),
          ),
          const SizedBox(height: 32),

          // À propos de l'application
          Text('L\'application',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'KASUWATA My Buz est une marketplace mobile qui connecte acheteurs et vendeurs '
            'locaux au sein d\'un même écosystème numérique. Trouvez des produits, '
            'passez vos commandes et participez à des Adashé (Adashen Waya) en toute simplicité.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(height: 1.6, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 28),

          // À propos de l'entreprise
          Text('L\'entreprise',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'KASUWATA My Buz est développée par TechInnov, une entreprise technologique '
            'engagée dans la transformation numérique du commerce local. '
            'Notre mission est de rendre le commerce accessible, transparent et '
            'équitable pour tous.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(height: 1.6, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 28),

          // Infos de contact
          Text('Contact',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const _ContactTile(
            icon: Icons.email_outlined,
            label: 'contact@kassouwata.com',
          ),
          const _ContactTile(
            icon: Icons.language_outlined,
            label: 'www.kassouwata.com',
          ),
          const SizedBox(height: 32),

          Center(
            child: Text(
              '© 2026 TechInnov. Tous droits réservés.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ContactTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
