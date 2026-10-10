import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/di/injection.dart';
import '../../../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../domain/entities/tontine_entity.dart';
import '../bloc/tontine_bloc.dart';
import '../widgets/tontine_card.dart';

class TontinesPage extends StatefulWidget {
  const TontinesPage({super.key});

  @override
  State<TontinesPage> createState() => _TontinesPageState();
}

class _TontinesPageState extends State<TontinesPage>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _userTelephone;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _searchCtrl.addListener(
        () => setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase()));
    _loadUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await getIt<AuthLocalDataSource>().getCachedUser();
    if (!mounted) return;
    setState(() => _userTelephone = user?.telephone);
    if (_userTelephone != null) {
      context.read<TontineBloc>().add(LoadTontinesFull(_userTelephone!));
    }
  }

  void _refresh() {
    if (_userTelephone != null) {
      context.read<TontineBloc>().add(LoadTontinesFull(_userTelephone!));
    }
  }

  List<TontineEntity> _filtered(List<TontineEntity> list) {
    if (_searchQuery.isEmpty) return list;
    return list
        .where((t) => t.libelle.toLowerCase().contains(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Tontines'),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.savings_outlined), text: 'Mes tontines'),
              Tab(icon: Icon(Icons.group_outlined), text: 'Rejointes'),
            ],
          ),
        ),
        floatingActionButton: _tabController.index == 0
            ? FloatingActionButton.extended(
                onPressed: () async {
                  await context.push('/tontines/add');
                  if (mounted) _refresh();
                },
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle tontine'),
              )
            : null,
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: BlocConsumer<TontineBloc, TontineState>(
                listener: (context, state) {
                  if (state is TontineFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ));
                  }
                  if (state is TontineOperationSuccess) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(state.message)));
                    _refresh();
                  }
                },
                builder: (context, state) {
                  if (state is TontineLoading || _userTelephone == null) {
                    return _buildShimmer();
                  }
                  if (state is TontinesFullLoaded) {
                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildList(
                          context,
                          _filtered(state.myTontines),
                          isOwned: true,
                          emptyMsg: 'Aucune tontine créée',
                          emptyHint: 'Appuyez sur + pour créer une tontine',
                        ),
                        _buildList(
                          context,
                          _filtered(state.joinedTontines),
                          isOwned: false,
                          emptyMsg: 'Aucune tontine rejointe',
                          emptyHint:
                              'Acceptez une invitation pour rejoindre une tontine',
                        ),
                      ],
                    );
                  }
                  if (state is TontineFailure) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          Text(state.message, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _refresh,
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<TontineEntity> tontines, {
    required bool isOwned,
    required String emptyMsg,
    required String emptyHint,
  }) {
    if (tontines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOwned ? Icons.savings_outlined : Icons.group_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Aucun résultat pour "$_searchQuery"'
                  : emptyMsg,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              Text(emptyHint,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center),
            ],
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
        itemCount: tontines.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final tontine = tontines[i];
          return TontineCard(
            tontine: tontine,
            onTap: () async {
              await context.push('/tontines/detail',
                  extra: {'tontine': tontine, 'isOwner': isOwned});
              if (mounted) _refresh();
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Rechercher une tontine…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchCtrl.clear(),
                )
              : null,
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Card(
          child: SizedBox(
            height: 80,
            child: Row(
              children: [
                const SizedBox(width: 14),
                Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    )),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          height: 14,
                          width: double.infinity,
                          color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 120, color: Colors.white),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
