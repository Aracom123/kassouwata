import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_bar_actions.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../bloc/boutique_bloc.dart';

class BoutiquesPage extends StatefulWidget {
  const BoutiquesPage({super.key});

  @override
  State<BoutiquesPage> createState() => _BoutiquesPageState();
}

class _BoutiquesPageState extends State<BoutiquesPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    context.read<BoutiqueBloc>().add(const LoadBoutiques());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boutiques'),
        actions: buildAppBarActions(context),
      ),
      body: BlocBuilder<BoutiqueBloc, BoutiqueState>(
        builder: (context, state) {
          if (state.status == BoutiqueStatus.initial ||
              state.status == BoutiqueStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == BoutiqueStatus.failure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(state.errorMessage ?? 'Erreur de chargement'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context
                        .read<BoutiqueBloc>()
                        .add(const LoadBoutiques()),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final activeBoutiques = state.boutiques
              .where((b) => b.isActive)
              .where((b) =>
                  _query.isEmpty ||
                  b.libelle.toLowerCase().contains(_query) ||
                  (b.adresse?.toLowerCase().contains(_query) ?? false))
              .toList();

          return Column(
            children: [
              // Barre de recherche
              AppSearchField(
                controller: _searchCtrl,
                hintText: 'Rechercher une boutique…',
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
              ),

              // Résultats
              Expanded(
                child: activeBoutiques.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.storefront_outlined,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              _query.isEmpty
                                  ? 'Aucune boutique active'
                                  : 'Aucun résultat pour "$_query"',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => context
                            .read<BoutiqueBloc>()
                            .add(const LoadBoutiques()),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.1,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: activeBoutiques.length,
                          itemBuilder: (context, index) {
                            final boutique = activeBoutiques[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.push(
                      '/boutiques/${boutique.idBoutique}',
                      extra: boutique.libelle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor:
                                theme.colorScheme.primaryContainer,
                            child: Text(
                              boutique.libelle.isNotEmpty
                                  ? boutique.libelle[0].toUpperCase()
                                  : '?',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            boutique.libelle,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (boutique.adresse != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              boutique.adresse!,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  },
      ),
    );
  }
}
