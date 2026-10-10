import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_bar_actions.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../bloc/catalogue_bloc.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    final state = context.read<CatalogueBloc>().state;
    if (state.categories.isEmpty) {
      context.read<CatalogueBloc>().add(const LoadCatalogue());
    }
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
        title: const Text('Catégories'),
        actions: buildAppBarActions(context),
      ),
      body: BlocBuilder<CatalogueBloc, CatalogueState>(
        builder: (context, state) {
          if ((state.status == CatalogueStatus.initial ||
                  state.status == CatalogueStatus.loading) &&
              state.categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.categories.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Aucune catégorie disponible',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // Filtrage local selon la saisie
          final filtered = _query.isEmpty
              ? state.categories
              : state.categories
                  .where((c) => c.libelle
                      .toLowerCase()
                      .contains(_query.toLowerCase()))
                  .toList();

          return Column(
            children: [
              // ─── Barre de recherche ──────────────────────────────────
              AppSearchField(
                controller: _searchCtrl,
                hintText: 'Rechercher une catégorie…',
                onChanged: (v) => setState(() => _query = v),
              ),

              // ─── Liste filtrée ───────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Aucune catégorie pour "$_query"',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 70),
                        itemBuilder: (context, index) {
                          final cat = filtered[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.secondaryContainer,
                              child: Icon(
                                Icons.category_outlined,
                                color: theme.colorScheme.secondary,
                                size: 20,
                              ),
                            ),
                            title: Text(cat.libelle,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push(
                              '/categories/${cat.idCategorie}',
                              extra: cat.libelle,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
