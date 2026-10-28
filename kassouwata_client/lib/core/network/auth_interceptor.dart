import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _storage;
  final void Function() onUnauthorized;

  AuthInterceptor(this._storage, {required this.onUnauthorized});

  // Routes accessibles sans token (miroir de SecurityConfig.java)
  static const _publicExact = {
    '/api/authenticate',
    '/api/nosUsers/register',
    '/api/nosUsers/send-otp',
    '/api/nosUsers/verify-otp',
    '/api/nosUsers/forgot-password',
    '/api/nosUsers/reset-password',
    '/api/nosUsers/saveClient',
    '/api/nosBoutiques/list',
    '/api/nosBoutiques/actives',
    '/api/nosCategories/list',
  };

  static const _publicPrefixes = [
    '/api/nosProduits/',
    '/images/',
  ];

  bool _isPublic(String path) {
    if (_publicExact.contains(path)) return true;
    for (final prefix in _publicPrefixes) {
      if (path.startsWith(prefix)) return true;
    }
    return false;
  }

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Routes publiques : on n'ajoute pas de token
    if (_isPublic(options.path)) {
      debugPrint('[AuthInterceptor] PUBLIC route: ${options.path}');
      return handler.next(options);
    }

    debugPrint('[AuthInterceptor] PROTECTED route: ${options.path}');

    // Vérification de l'expiration avant toute requête protégée
    final expired = await _storage.isTokenExpired();
    if (expired) {
      debugPrint('[AuthInterceptor] Token expired — cancelling: ${options.path}');
      await _storage.clearAll();
      onUnauthorized();
      return handler.reject(
        DioException(
          requestOptions: options,
          error: 'Session expirée. Veuillez vous reconnecter.',
          type: DioExceptionType.cancel,
        ),
      );
    }

    final token = await _storage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _storage.clearAll();
      onUnauthorized();
    }
    handler.next(err);
  }
}
