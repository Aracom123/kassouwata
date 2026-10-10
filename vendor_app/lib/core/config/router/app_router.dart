import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/di/injection.dart';
import '../../../features/products/presentation/bloc/product_bloc.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/auth/presentation/pages/login_page.dart';
import '../../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../../features/auth/presentation/pages/register_page.dart';
import '../../../features/auth/presentation/pages/splash_page.dart';
import '../../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../../features/onboarding/presentation/pages/complete_profile_page.dart';
import '../../../features/onboarding/presentation/pages/create_boutique_page.dart';
import '../../../features/orders/domain/entities/order_entity.dart';
import '../../../features/orders/presentation/bloc/order_bloc.dart';
import '../../../features/orders/presentation/pages/order_detail_page.dart';
import '../../../features/orders/presentation/pages/orders_page.dart';
import '../../../features/products/domain/entities/product_entity.dart';
import '../../../features/products/presentation/pages/add_product_page.dart';
import '../../../features/products/presentation/pages/products_page.dart';
import '../../../features/tontine/domain/entities/tontine_entity.dart';
import '../../../features/tontine/presentation/bloc/tontine_bloc.dart';
import '../../../features/tontine/presentation/pages/add_periode_page.dart';
import '../../../features/tontine/presentation/pages/add_tontine_page.dart';
import '../../../features/tontine/presentation/pages/periode_detail_page.dart';
import '../../../features/tontine/presentation/pages/tontine_detail_page.dart';
import '../../../features/tontine/presentation/pages/tontines_page.dart';
import '../../../features/profile/presentation/pages/edit_boutique_page.dart';
import '../../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../../features/profile/presentation/pages/profile_page.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterPage(),
      ),
      GoRoute(
        path: '/otp-verify',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return BlocProvider(
            create: (_) => getIt<AuthBloc>(),
            child: OtpVerificationPage(
              telephone: extra['telephone'] as String? ?? '',
              password: extra['password'] as String? ?? '',
              prenom: extra['prenom'] as String?,
              nom: extra['nom'] as String?,
            ),
          );
        },
      ),
      // --- Profile ---
      GoRoute(
        path: '/edit-profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/shop-settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const EditBoutiquePage(),
      ),

      // --- Onboarding ---
      GoRoute(
        path: '/complete-profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CompleteProfilePage(
            idUser: extra['idUser'] as String? ?? '',
            nom: extra['nom'] as String? ?? '',
            prenom: extra['prenom'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/create-boutique',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CreateBoutiquePage(
            idUser: extra['idUser'] as String? ?? '',
          );
        },
      ),

      // --- Order detail (full-screen, above ShellRoute) ---
      GoRoute(
        path: '/orders/detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return BlocProvider(
            create: (_) => getIt<OrderBloc>(),
            child: OrderDetailPage(
              order: extra['order'] as OrderEntity,
              idBoutique: extra['idBoutique'] as int,
            ),
          );
        },
      ),

      // --- Product routes (full-screen, above ShellRoute) ---
      GoRoute(
        path: '/products/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const AddProductPage(),
      ),
      GoRoute(
        path: '/products/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => AddProductPage(
          product: state.extra as ProductEntity?,
        ),
      ),

      // --- Tontine routes (full-screen, above ShellRoute) ---
      GoRoute(
        path: '/tontines/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const AddTontinePage(),
      ),
      GoRoute(
        path: '/tontines/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => AddTontinePage(
          tontine: state.extra as TontineEntity?,
        ),
      ),
      GoRoute(
        path: '/tontines/detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return TontineDetailPage(
            tontine: extra['tontine'] as TontineEntity,
            isOwner: extra['isOwner'] as bool? ?? true,
          );
        },
      ),
      GoRoute(
        path: '/tontines/periodes/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return AddPeriodePage(
            tontine: extra['tontine'] as TontineEntity,
            periode: extra['periode'] as PeriodeVersementEntity?,
            members: (extra['members'] as List<DemandeAdhesionEntity>?) ?? [],
          );
        },
      ),
      GoRoute(
        path: '/tontines/periodes/detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return PeriodeDetailPage(
            tontine: extra['tontine'] as TontineEntity,
            periode: extra['periode'] as PeriodeVersementEntity,
            members: (extra['members'] as List<DemandeAdhesionEntity>?) ?? [],
            isOwner: extra['isOwner'] as bool? ?? true,
          );
        },
      ),

      // --- App principale (avec barre de navigation) ---
      ShellRoute(
        builder: (context, state, child) => _MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => BlocProvider(
              create: (_) => getIt<DashboardBloc>()..add(const LoadDashboard()),
              child: const DashboardPage(),
            ),
          ),
          GoRoute(
            path: '/products',
            builder: (_, __) => BlocProvider(
              create: (_) => getIt<ProductBloc>(),
              child: const ProductsPage(),
            ),
          ),
          GoRoute(
            path: '/orders',
            builder: (_, __) => BlocProvider(
              create: (_) => getIt<OrderBloc>(),
              child: const OrdersPage(),
            ),
          ),
          GoRoute(
            path: '/tontines',
            builder: (_, __) => BlocProvider(
              create: (_) => getIt<TontineBloc>(),
              child: const TontinesPage(),
            ),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfilePage(),
          ),
        ],
      ),
    ],
  );
}

class _MainScaffold extends StatelessWidget {
  final Widget child;
  const _MainScaffold({required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/products')) return 1;
    if (location.startsWith('/orders')) return 2;
    if (location.startsWith('/tontines')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (i) {
          const routes = [
            '/dashboard',
            '/products',
            '/orders',
            '/tontines',
            '/profile',
          ];
          final route = routes[i];
          context.go(route);
          getIt<SharedPreferences>().setString('lastMainRoute', route);
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined), label: 'Accueil'),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined), label: 'Produits'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined), label: 'Commandes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.savings_outlined), label: 'Tontines'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}