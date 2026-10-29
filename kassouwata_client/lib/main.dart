import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/config/router/app_router.dart';
import 'core/config/theme/app_theme.dart';
import 'core/di/injection.dart';
import 'core/network/dio_client.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/boutique/presentation/bloc/boutique_bloc.dart';
import 'features/cart/presentation/bloc/cart_bloc.dart';
import 'features/catalogue/presentation/bloc/catalogue_bloc.dart';
import 'features/orders/presentation/bloc/order_bloc.dart';
import 'features/tontine/presentation/bloc/tontine_client_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment — production en release, développement sinon
  final envFile = kReleaseMode ? '.env.production' : '.env.development';
  await dotenv.load(fileName: envFile);

  // Setup dependency injection
  await configureDependencies();

  runApp(const KassouwataClientApp());
}

class KassouwataClientApp extends StatefulWidget {
  const KassouwataClientApp({super.key});

  @override
  State<KassouwataClientApp> createState() => _KassouwataClientAppState();
}

class _KassouwataClientAppState extends State<KassouwataClientApp> {
  late final StreamSubscription<void> _sessionSub;

  @override
  void initState() {
    super.initState();
    // Quand le token expire en cours de session, on redirige vers /login
    _sessionSub = getIt<DioClient>().sessionExpired.listen((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appRouter.go('/login');
      });
    });
  }

  @override
  void dispose() {
    _sessionSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => getIt<AuthBloc>(),
        ),
        BlocProvider<CartBloc>(
          create: (_) => getIt<CartBloc>(),
        ),
        BlocProvider<CatalogueBloc>(
          create: (_) => getIt<CatalogueBloc>(),
        ),
        BlocProvider<OrderBloc>(
          create: (_) => getIt<OrderBloc>(),
        ),
        BlocProvider<TontineClientBloc>(
          create: (_) => getIt<TontineClientBloc>(),
        ),
        BlocProvider<BoutiqueBloc>(
          create: (_) => getIt<BoutiqueBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'KASUWATA My Buz',
        theme: AppTheme.light,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
        restorationScopeId: 'app',
      ),
    );
  }
}
