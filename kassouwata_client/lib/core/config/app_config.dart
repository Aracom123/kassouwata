import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'http://192.168.0.130:8082';

  /// ID du profil CLIENT dans la base de données
  static const int clientProfileId = 3;

  /// ID du profil VENDEUR dans la base de données
  static const int vendeurProfileId = 2;
}
