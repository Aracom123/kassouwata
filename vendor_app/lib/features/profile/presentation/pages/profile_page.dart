import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../../../features/auth/data/models/user_model.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/shop/data/models/shop_model.dart';
import '../../../../shared/enums/boutique_status.dart';
import '../../../../shared/enums/user_status.dart';
import '../../../../shared/theme/app_colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel? _user;
  ShopModel? _boutique;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final ds = getIt<AuthLocalDataSource>();
    final results = await Future.wait([ds.getCachedUser(), ds.getCachedBoutique()]);
    if (mounted) {
      setState(() {
        _user = results[0] as UserModel?;
        _boutique = results[1] as ShopModel?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>(),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated) context.go('/login');
        },
        child: Builder(builder: (context) => PopScope(
          // Intercepte le bouton retour Android pour éviter de quitter l'app
          // depuis une page racine du ShellRoute : redirige vers /dashboard
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) context.go('/dashboard');
          },
          child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildIdentitySection(),
                      const SizedBox(height: 12),
                      _buildContactSection(),
                      const SizedBox(height: 12),
                      _buildAccountSection(),
                      const SizedBox(height: 12),
                      _buildBoutiqueSection(context),
                      const SizedBox(height: 24),
                      _buildLogoutButton(context),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ))),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final prenom = _user?.personne?.prenom ?? '';
    final nom = _user?.personne?.nom ?? '';
    final fullName = (prenom.isNotEmpty || nom.isNotEmpty)
        ? '$prenom $nom'.trim()
        : 'Vendeur';
    final telephone = _user?.telephone ?? '';
    final initials = _initials(prenom, nom);

    return SliverToBoxAdapter(
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          children: [
            Row(
              children: [
                const Spacer(),
                IconButton(
                  onPressed: () async {
                    // push retourne true si le profil a été modifié
                    final updated = await context.push<bool>('/edit-profile');
                    if (updated == true) _loadData();
                  },
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Modifier le profil',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              fullName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.grey900,
              ),
            ),
            if (telephone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                telephone,
                style: const TextStyle(fontSize: 14, color: AppColors.grey600),
              ),
            ],
            const SizedBox(height: 12),
            _buildStatusBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final status = _user?.status;
    if (status == null) return const SizedBox.shrink();

    final (label, color) = switch (status) {
      UserStatus.active => ('Compte actif', AppColors.success),
      UserStatus.kycPending => ('En attente de validation', AppColors.warning),
      UserStatus.phoneUnverified => ('Numéro non vérifié', AppColors.warning),
      UserStatus.suspended => ('Suspendu', AppColors.error),
      UserStatus.blocked => ('Bloqué', AppColors.error),
      UserStatus.closed => ('Fermé', AppColors.grey400),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySection() {
    final p = _user?.personne;
    return _buildSection(
      title: 'Identité',
      icon: Icons.person_outline,
      rows: [
        _InfoRow(label: 'Prénom', value: p?.prenom),
        _InfoRow(label: 'Nom', value: p?.nom),
        _InfoRow(label: 'Genre', value: p?.genre),
        _InfoRow(
          label: 'Date de naissance',
          value: p?.dateNaissance != null ? _formatDate(p!.dateNaissance!) : null,
        ),
        _InfoRow(label: 'Lieu de naissance', value: p?.lieuNaissance),
      ],
    );
  }

  Widget _buildContactSection() {
    final p = _user?.personne;
    return _buildSection(
      title: 'Coordonnées',
      icon: Icons.contact_mail_outlined,
      rows: [
        _InfoRow(label: 'Téléphone', value: _user?.telephone),
        _InfoRow(label: 'Email', value: p?.email?.isNotEmpty == true ? p!.email : null),
        _InfoRow(label: 'Adresse', value: p?.adresse),
      ],
    );
  }

  Widget _buildAccountSection() {
    return _buildSection(
      title: 'Compte',
      icon: Icons.store_outlined,
      rows: [
        _InfoRow(label: 'Profil', value: _user?.profile?.libelle),
        _InfoRow(label: 'Identifiant', value: _user?.idUser),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<_InfoRow> rows,
  }) {
    final visibleRows = rows.where((r) => r.value != null && r.value!.isNotEmpty).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.grey200),
          if (visibleRows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Aucune information renseignée',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.grey400,
                    fontStyle: FontStyle.italic),
              ),
            )
          else
            ...visibleRows.asMap().entries.map((entry) {
              final i = entry.key;
              final row = entry.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 130,
                          child: Text(
                            row.label,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.grey400,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            row.value!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.grey900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < visibleRows.length - 1)
                    const Divider(
                        height: 1, indent: 16, color: AppColors.grey200),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBoutiqueSection(BuildContext context) {
    final b = _boutique;
    final (statusLabel, statusColor) = b == null
        ? ('', AppColors.grey400)
        : switch (b.status) {
            BoutiqueStatus.active => ('Active', AppColors.success),
            BoutiqueStatus.pending => ('En attente', AppColors.warning),
            BoutiqueStatus.suspended => ('Suspendue', AppColors.error),
            BoutiqueStatus.closed => ('Fermée', AppColors.grey400),
          };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.store_outlined, size: 16, color: AppColors.secondary),
                const SizedBox(width: 8),
                const Text(
                  'MA BOUTIQUE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    final updated = await context.push<bool>('/shop-settings');
                    if (updated == true) _loadData();
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 14, color: AppColors.secondary),
                      SizedBox(width: 4),
                      Text(
                        'Modifier',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.grey200),
          if (b == null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Aucune boutique créée',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.grey400,
                    fontStyle: FontStyle.italic),
              ),
            )
          else ...[
            _boutiqueRow('Nom', b.libelle),
            if (b.description != null && b.description!.isNotEmpty) ...[
              const Divider(height: 1, indent: 16, color: AppColors.grey200),
              _boutiqueRow('Description', b.description!),
            ],
            if (b.adresse != null && b.adresse!.isNotEmpty) ...[
              const Divider(height: 1, indent: 16, color: AppColors.grey200),
              _boutiqueRow('Adresse', b.adresse!),
            ],
            const Divider(height: 1, indent: 16, color: AppColors.grey200),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const SizedBox(
                    width: 130,
                    child: Text('Statut',
                        style: TextStyle(fontSize: 13, color: AppColors.grey400)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: statusColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        Text(statusLabel,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, indent: 16, color: AppColors.grey200),
            _boutiqueRow('Commission', '${b.commission.toStringAsFixed(1)}%'),
          ],
        ],
      ),
    );
  }

  Widget _boutiqueRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: AppColors.grey400)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey900)),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    return OutlinedButton.icon(
      onPressed: () => _confirmLogout(context, authBloc),
      icon: const Icon(Icons.logout_rounded, color: AppColors.error),
      label: const Text(
        'Se déconnecter',
        style: TextStyle(color: AppColors.error),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: AppColors.error),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthBloc authBloc) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Se déconnecter'),
        content: const Text('Voulez-vous vraiment fermer votre session ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              authBloc.add(const LogoutRequested());
            },
            child: const Text(
              'Se déconnecter',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _initials(String prenom, String nom) {
    final p = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final n = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    return '$p$n'.isNotEmpty ? '$p$n' : '?';
  }
}

class _InfoRow {
  final String label;
  final String? value;
  const _InfoRow({required this.label, required this.value});
}
