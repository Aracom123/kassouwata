import 'package:flutter/material.dart';

class CguPage extends StatelessWidget {
  const CguPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Conditions Générales d'Utilisation")),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            "Conditions Générales d'Utilisation",
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Dernière mise à jour : janvier 2026',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          const _Section(
            title: '1. Présentation',
            body:
                "L'application Kassouwata est éditée par TechInnov. Elle a pour vocation "
                "de mettre en relation des acheteurs et des vendeurs au sein d'une "
                "marketplace numérique. En utilisant l'application, vous acceptez "
                "sans réserve les présentes conditions.",
          ),
          const _Section(
            title: '2. Accès au service',
            body:
                "L'accès à l'application est gratuit. Certaines fonctionnalités "
                "(commandes, tontines) nécessitent la création d'un compte. "
                "Vous vous engagez à fournir des informations exactes et à maintenir "
                "la confidentialité de vos identifiants.",
          ),
          const _Section(
            title: '3. Utilisation du service',
            body:
                "Vous vous engagez à utiliser l'application de manière conforme à la loi "
                "et aux présentes conditions. Tout usage frauduleux, abusif ou contraire "
                "à l'ordre public entraînera la suspension immédiate du compte concerné.",
          ),
          const _Section(
            title: '4. Responsabilité des vendeurs',
            body:
                "Les vendeurs sont seuls responsables des produits qu'ils proposent, "
                "de leur conformité et de leur livraison. TechInnov agit en qualité "
                "d'intermédiaire technique et ne saurait être tenu responsable des "
                "transactions entre utilisateurs.",
          ),
          const _Section(
            title: '5. Données personnelles',
            body:
                "Vos données sont collectées et traitées conformément à la réglementation "
                "en vigueur. Elles ne sont ni vendues ni cédées à des tiers sans votre "
                "consentement. Vous disposez d'un droit d'accès, de rectification et de "
                "suppression de vos données en nous contactant à contact@kassouwata.com.",
          ),
          const _Section(
            title: '6. Propriété intellectuelle',
            body:
                "L'ensemble des contenus présents sur Kassouwata (logo, textes, "
                "interfaces) est la propriété exclusive de TechInnov et est protégé "
                "par le droit d'auteur. Toute reproduction sans autorisation est interdite.",
          ),
          const _Section(
            title: '7. Modification des CGU',
            body:
                "TechInnov se réserve le droit de modifier les présentes conditions "
                "à tout moment. Les utilisateurs seront informés de toute modification "
                "substantielle. La poursuite de l'utilisation du service vaut acceptation "
                "des nouvelles conditions.",
          ),
          const _Section(
            title: '8. Contact',
            body:
                "Pour toute question relative aux présentes CGU, vous pouvez nous "
                "contacter à : contact@kassouwata.com",
          ),

          const SizedBox(height: 16),
          Center(
            child: Text(
              '© 2026 TechInnov. Tous droits réservés.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(body,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(height: 1.6, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
