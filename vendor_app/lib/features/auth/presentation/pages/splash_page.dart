import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../../../features/shop/data/datasources/shop_remote_datasource.dart';
import '../../../../features/auth/data/models/user_model.dart';
import '../../../../shared/enums/user_status.dart';
import '../../../../shared/theme/app_colors.dart';
import 'unauthorized_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final token = await getIt<SecureStorage>().getAccessToken();
    if (!mounted) return;
    if (token == null) {
      context.go('/login');
      return;
    }

    final cachedUser = await getIt<AuthLocalDataSource>().getCachedUser();
    if (!mounted) return;
    if (cachedUser == null) {
      context.go('/login');
      return;
    }

    if (cachedUser.status == UserStatus.kycPending) {
      context.go('/complete-profile', extra: {
        'idUser': cachedUser.idUser,
        'nom': cachedUser.personne?.nom ?? '',
        'prenom': cachedUser.personne?.prenom ?? '',
      });
      return;
    }

    final isVendeur =
        cachedUser.profile?.libelle.toUpperCase() == 'VENDEUR';

    // Compte non vendeur → accès refusé
    if (!isVendeur) {
      showUnauthorizedModal(context, telephone: cachedUser.telephone);
      return;
    }

    // Vérification boutique : cache d'abord, puis API si cache vide
    var cachedBoutique =
        await getIt<AuthLocalDataSource>().getCachedBoutique();
    if (!mounted) return;

    if (cachedBoutique == null) {
      // Pas de cache (réinstallation, effacement données) → vérifier en base
      try {
        final boutique = await getIt<ShopRemoteDataSource>()
            .getBoutiqueByVendeur(cachedUser.idUser);
        // Boutique trouvée en base → la mettre en cache et continuer
        await getIt<AuthLocalDataSource>().cacheBoutique(boutique);
        cachedBoutique = boutique;
      } catch (_) {
        // 404 ou erreur réseau → pas de boutique, rediriger vers création
        if (!mounted) return;
        context.go('/create-boutique', extra: {'idUser': cachedUser.idUser});
        return;
      }
    }

    if (!mounted) return;

    // Vendeur avec boutique → interface principale
    final lastRoute =
        getIt<SharedPreferences>().getString('lastMainRoute') ?? '/dashboard';
    context.go(lastRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store_rounded, size: 80, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Kassouwata',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gérez votre boutique',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}