import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import 'api_endpoints.dart';
import 'auth_interceptor.dart';

@singleton
class DioClient {
  late final Dio dio;

  DioClient(SecureStorage secureStorage) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        sendTimeout: AppConfig.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    final authInterceptor = AuthInterceptor(secureStorage);

    dio.interceptors.addAll([
      authInterceptor,
      if (AppConfig.isDevelopment)
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          compact: false,
          // Jamais de journalisation des paiements : le corps peut contenir
          // un numéro de carte et un CVV.
          filter: (options, _) => !options.path.contains(ApiEndpoints.payer),
        ),
    ]);
  }
}
