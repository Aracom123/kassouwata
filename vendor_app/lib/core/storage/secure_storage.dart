import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@singleton
class SecureStorage {
  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _expiresInKey = 'token_expires_in';

  const SecureStorage(this._storage);

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<String?> getAccessToken() =>
      _storage.read(key: _accessTokenKey);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<String?> getRefreshToken() =>
      _storage.read(key: _refreshTokenKey);

  Future<void> saveUserId(String userId) =>
      _storage.write(key: _userIdKey, value: userId);

  Future<String?> getUserId() =>
      _storage.read(key: _userIdKey);

  Future<void> saveExpiresIn(int millisecondsSinceEpoch) =>
      _storage.write(key: _expiresInKey, value: millisecondsSinceEpoch.toString());

  Future<int?> getExpiresIn() async {
    final value = await _storage.read(key: _expiresInKey);
    return value != null ? int.tryParse(value) : null;
  }

  Future<void> clearAll() => _storage.deleteAll();
}
