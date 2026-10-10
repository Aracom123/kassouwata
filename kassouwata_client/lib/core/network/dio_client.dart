import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import 'api_endpoints.dart';
import 'auth_interceptor.dart';

@singleton
class DioClient {
  late final Dio dio;

  final _sessionExpiredController = StreamController<void>.broadcast();

  /// Émet un événement quand le token est expiré ou invalidé côté serveur.
  /// Écoutez ce stream pour rediriger vers /login.
  Stream<void> get sessionExpired => _sessionExpiredController.stream;

  DioClient(SecureStorage storage) {
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(
      AuthInterceptor(storage, onUnauthorized: () {
        _sessionExpiredController.add(null);
      }),
    );

    // Journalisation en debug uniquement. Les requêtes de paiement ne sont
    // jamais journalisées : leur corps peut contenir un numéro de carte / CVV.
    if (kDebugMode) {
      dio.interceptors.add(PrettyDioLogger(
        requestBody: true,
        responseBody: false,
        compact: true,
        filter: (options, _) => !options.path.contains(ApiEndpoints.payer),
      ));
    }
  }

  void dispose() => _sessionExpiredController.close();
}
