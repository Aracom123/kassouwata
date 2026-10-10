import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/app_config.dart';
import 'core/config/router/app_router.dart';
import 'core/di/injection.dart';
import 'core/network/auth_navigator.dart';
import 'shared/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables — production en release, développement sinon
  final envFile = kReleaseMode ? '.env.production' : '.env.development';
  await dotenv.load(fileName: envFile);

  // Initialize dependency injection
  await configureDependencies(AppConfig.environment);

  // Redirect to login on expired/invalid token
  AuthNavigator.onUnauthorized = () {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppRouter.router.go('/login');
    });
  };

  runApp(const VendorApp());
}

class VendorApp extends StatelessWidget {
  const VendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Vendor App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
