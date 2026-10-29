import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../features/about/presentation/pages/about_page.dart';
import '../../../features/about/presentation/pages/cgu_page.dart';
import '../../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../../features/auth/presentation/pages/login_page.dart';
import '../../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../../features/auth/presentation/pages/register_page.dart';
import '../../../features/auth/presentation/pages/splash_page.dart';
import '../../../features/boutique/presentation/pages/boutique_products_page.dart';
import '../../../features/boutique/presentation/pages/boutiques_page.dart';
import '../../../features/cart/presentation/pages/cart_page.dart';
import '../../../features/catalogue/presentation/pages/categories_page.dart';
import '../../../features/catalogue/presentation/pages/catalogue_page.dart';
import '../../../features/catalogue/presentation/pages/category_products_page.dart';
import '../../../features/catalogue/presentation/pages/product_detail_page.dart';
import '../../../features/orders/presentation/pages/checkout_page.dart';
import '../../../features/paiement/data/paiement_models.dart';
import '../../../features/paiement/presentation/pages/paiement_page.dart';
import '../../../features/orders/domain/entities/order_entity.dart';
import '../../../features/orders/presentation/pages/order_detail_page.dart';
import '../../../features/orders/presentation/pages/orders_page.dart';
import '../../../features/profile/presentation/bloc/complete_profile_bloc.dart';
import '../../../features/profile/presentation/pages/complete_profile_page.dart';
import '../../../features/profile/presentation/pages/change_telephone_page.dart';
import '../../../features/profile/presentation/pages/profile_page.dart';
import '../../../features/tontine/domain/entities/demande_entity.dart';
import '../../../features/tontine/presentation/pages/adashe_dashboard_page.dart';
import '../../../features/tontine/presentation/pages/tontine_detail_page.dart';
import '../../../features/tontine/presentation/pages/tontine_list_page.dart';
import '../../../features/tontine/presentation/pages/tontine_membre_detail_page.dart';
import '../../../features/tontine/presentation/pages/tontine_periods_page.dart';
import '../../../espaces/espace.dart';
import '../../../espaces/espace_shell.dart';
import '../../../espaces/espaces_page.dart';

// Espace vendeur (« Ma boutique ») — profil VENDEUR uniquement
import '../../../vendeur/ma_boutique_page.dart';
import '../../../vendeur/vendeur_session.dart';
import '../../../vendeur/features/orders/domain/entities/order_entity.dart' as v_ord;
import '../../../vendeur/features/orders/presentation/bloc/order_bloc.dart' as v_ord;
import '../../../vendeur/features/orders/presentation/pages/order_detail_page.dart' as v_ord;
import '../../../vendeur/features/orders/presentation/pages/orders_page.dart' as v_ord;
import '../../../vendeur/features/products/domain/entities/product_entity.dart' as v_prod;
import '../../../vendeur/features/products/presentation/bloc/product_bloc.dart' as v_prod;
import '../../../vendeur/features/products/presentation/pages/add_product_page.dart' as v_prod;
import '../../../vendeur/features/products/presentation/pages/products_page.dart' as v_prod;
import '../../../vendeur/features/profile/presentation/pages/edit_boutique_page.dart';
import '../../../features/tontine/presentation/pages/creer_adashe_produit_page.dart';
import '../../../features/catalogue/domain/entities/product_entity.dart';
import '../../../vendeur/demandes_adashe_page.dart';

/// Écrans de gestion de boutique : réservés aux vendeurs (sinon retour au
/// tableau de bord de l'espace Vendeur, qui propose « Devenir vendeur »).
Future<String?> _reserveVendeur(BuildContext context, GoRouterState state) async =>
    await getIt<VendeurSession>().estConnecteCommeVendeur() ? null : '/vendeur';

/// Création de boutique : tout compte connecté (un client devient vendeur).
Future<String?> _reserveConnecte(BuildContext context, GoRouterState state) async {
  final token = await getIt<SecureStorage>().getToken();
  return (token == null || token.isEmpty) ? '/vendeur' : null;
}

final appRouter = GoRouter(
  initialLocation: '/',
  restorationScopeId: 'router',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/espaces',
      builder: (context, state) => const EspacesPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) {
        final redirectTo = state.extra as String?;
        return LoginPage(redirectTo: redirectTo);
      },
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) =>
          ForgotPasswordPage(telephone: state.extra as String?),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) {
        final redirectTo = state.extra as String?;
        return RegisterPage(redirectTo: redirectTo);
      },
    ),
    GoRoute(
      path: '/otp-verify',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return OtpVerificationPage(
          telephone: extra['telephone'] as String? ?? '',
          password: extra['password'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartPage(),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutPage(),
    ),
    GoRoute(
      path: '/complete-profile',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final idUser = extra['idUser'] as String? ?? '';
        final prenom = extra['prenom'] as String? ?? '';
        final nom = extra['nom'] as String? ?? '';
        return BlocProvider(
          create: (_) => getIt<CompleteProfileBloc>(),
          child: CompleteProfilePage(idUser: idUser, prenom: prenom, nom: nom),
        );
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/changer-numero',
      builder: (context, state) => const ChangeTelephonePage(),
    ),
    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutPage(),
    ),
    GoRoute(
      path: '/cgu',
      builder: (context, state) => const CguPage(),
    ),
    GoRoute(
      path: '/adashe-produit/nouveau',
      builder: (context, state) =>
          CreerAdasheProduitPage(produit: state.extra as ProductEntity),
    ),
    GoRoute(
      path: '/vendeur/adashe',
      redirect: _reserveVendeur,
      builder: (context, state) => const DemandesAdashePage(),
    ),
    GoRoute(
      path: '/paiement',
      builder: (context, state) =>
          PaiementPage(args: state.extra as PaiementArgs),
    ),

    // ── Espace Vendeur : écrans plein écran ─────────────────────────────────
    GoRoute(
      path: '/creer-boutique',
      redirect: _reserveConnecte,
      builder: (context, state) => const CreerBoutiquePage(),
    ),
    GoRoute(
      path: '/vendeur/produits/ajout',
      redirect: _reserveVendeur,
      builder: (context, state) => const v_prod.AddProductPage(),
    ),
    GoRoute(
      path: '/vendeur/produits/modifier',
      redirect: _reserveVendeur,
      builder: (context, state) => v_prod.AddProductPage(
        product: state.extra as v_prod.ProductEntity?,
      ),
    ),
    GoRoute(
      path: '/vendeur/commandes/detail',
      redirect: _reserveVendeur,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return BlocProvider(
          create: (_) => getIt<v_ord.OrderBloc>(),
          child: v_ord.OrderDetailPage(
            order: extra['order'] as v_ord.OrderEntity,
            idBoutique: extra['idBoutique'] as int,
          ),
        );
      },
    ),

    // ── Espace Acheteur ─────────────────────────────────────────────────────
    ShellRoute(
      builder: (context, state, child) =>
          EspaceShell(espace: Espace.acheteur, child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const CataloguePage(),
        ),
        GoRoute(
          path: '/products/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return ProductDetailPage(productId: id);
          },
        ),
        GoRoute(
          path: '/categories',
          builder: (context, state) => const CategoriesPage(),
        ),
        GoRoute(
          path: '/categories/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            final name = state.extra as String? ?? 'Catégorie';
            return CategoryProductsPage(
                categoryId: id, categoryName: name);
          },
        ),
        GoRoute(
          path: '/boutiques',
          builder: (context, state) => const BoutiquesPage(),
        ),
        GoRoute(
          path: '/boutiques/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            final name = state.extra as String? ?? 'Boutique';
            return BoutiqueProductsPage(
                boutiqueId: id, boutiqueName: name);
          },
        ),
        GoRoute(
          path: '/orders',
          builder: (context, state) => const OrdersPage(),
        ),
        GoRoute(
          path: '/orders/:id',
          builder: (context, state) {
            final order = state.extra as OrderEntity;
            return OrderDetailPage(order: order);
          },
        ),
      ],
    ),

    // ── Espace Vendeur ──────────────────────────────────────────────────────
    ShellRoute(
      builder: (context, state, child) =>
          EspaceShell(espace: Espace.vendeur, child: child),
      routes: [
        GoRoute(
          path: '/vendeur',
          builder: (context, state) => const MaBoutiquePage(),
        ),
        GoRoute(
          path: '/vendeur/produits',
          redirect: _reserveVendeur,
          builder: (context, state) => BlocProvider(
            create: (_) => getIt<v_prod.ProductBloc>(),
            child: const v_prod.ProductsPage(),
          ),
        ),
        GoRoute(
          path: '/vendeur/commandes',
          redirect: _reserveVendeur,
          builder: (context, state) => BlocProvider(
            create: (_) => getIt<v_ord.OrderBloc>(),
            child: const v_ord.OrdersPage(),
          ),
        ),
        GoRoute(
          path: '/vendeur/boutique',
          redirect: _reserveVendeur,
          builder: (context, state) => const EditBoutiquePage(),
        ),
      ],
    ),

    // ── Espace Adashen Waya ─────────────────────────────────────────────────
    ShellRoute(
      builder: (context, state, child) =>
          EspaceShell(espace: Espace.adashe, child: child),
      routes: [
        GoRoute(
          path: '/adashe',
          builder: (context, state) => const AdasheDashboardPage(),
        ),
        GoRoute(
          path: '/tontines',
          builder: (context, state) => const TontineListPage(),
        ),
        GoRoute(
          path: '/tontines/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            final tontine = state.extra as TontineEntity;
            return TontineDetailPage(tontineId: id, tontine: tontine);
          },
        ),
        GoRoute(
          path: '/tontines/:id/member',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            final libelle = state.extra as String?;
            return TontineMembreDetailPage(
                tontineId: id, tontineLibelle: libelle);
          },
        ),
        GoRoute(
          path: '/tontines/:id/periods',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return TontinePeriodsPage(tontineId: id);
          },
        ),
        GoRoute(
          path: '/adashe/compte',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    ),
  ],
);
