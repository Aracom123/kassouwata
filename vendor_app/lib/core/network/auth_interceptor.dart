import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import 'auth_navigator.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage;

  AuthInterceptor(this._secureStorage);

  // Routes accessibles sans token — on n'attache pas le JWT
  static const _publicPaths = {
    '/api/authenticate',
    '/api/nosUsers/register',
    '/api/nosUsers/send-otp',
    '/api/nosUsers/verify-otp',
    '/api/nosUsers/saveClient',
  };

  // Routes publiques avec préfixe (GET uniquement, pas de token requis)
  static const _publicPrefixes = {
    '/api/nosProduits/',
    '/api/nosCategories/',
    '/images/',
  };

  // Routes publiques exactes supplémentaires
  static const _publicExactExtra = {
    '/api/nosBoutiques/list',
  };

  bool _isPublic(String path) {
    if (_publicPaths.contains(path)) return true;
    if (_publicExactExtra.contains(path)) return true;
    for (final prefix in _publicPrefixes) {
      if (path.startsWith(prefix)) return true;
    }
    return false;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Routes publiques : pas de token, pas de vérification d'expiration
    if (_isPublic(options.path)) {
      handler.next(options);
      return;
    }

    final expiresInMs = await _secureStorage.getExpiresIn();
    if (expiresInMs != null &&
        DateTime.now().millisecondsSinceEpoch >= expiresInMs) {
      await _secureStorage.clearAll();
      AuthNavigator.sessionExpired = true;
      AuthNavigator.onUnauthorized?.call();
      handler.reject(DioException(
        requestOptions: options,
        type: DioExceptionType.cancel,
        message: 'Session expirée',
      ));
      return;
    }

    final token = await _secureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Session expirée détectée localement (onRequest a déjà redirigé) :
    // on rejette sans propager pour éviter un double traitement dans le bloc.
    if (err.type == DioExceptionType.cancel) {
      handler.reject(err);
      return;
    }
    final status = err.response?.statusCode;
    if (status == 401) {
      // Sur les routes publiques (ex: /authenticate), un 401 signifie
      // identifiants incorrects — on laisse le datasource le gérer normalement.
      final path = err.requestOptions.path;
      if (_isPublic(path)) {
        handler.next(err);
        return;
      }
      // Sur les routes protégées, un 401 signifie session expirée.
      await _secureStorage.clearAll();
      AuthNavigator.sessionExpired = true;
      AuthNavigator.onUnauthorized?.call();
      handler.reject(err);
      return;
    }
    handler.next(err);
  }
}