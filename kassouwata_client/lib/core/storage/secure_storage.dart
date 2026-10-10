import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@singleton
class SecureStorage {
  final FlutterSecureStorage _storage;
  const SecureStorage(this._storage);

  static const _tokenKey      = 'auth_token';
  static const _userIdKey     = 'user_id';
  static const _profileKey    = 'user_profile';
  static const _telephoneKey  = 'user_telephone';
  static const _expiresInKey  = 'token_expires_in';
  static const _statusKey     = 'user_status';
  static const _prenomKey     = 'user_prenom';
  static const _nomKey        = 'user_nom';

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> saveUserId(String id) => _storage.write(key: _userIdKey, value: id);
  Future<String?> getUserId() => _storage.read(key: _userIdKey);

  Future<void> saveProfile(String profile) => _storage.write(key: _profileKey, value: profile);
  Future<String?> getProfile() => _storage.read(key: _profileKey);

  Future<void> saveTelephone(String tel) => _storage.write(key: _telephoneKey, value: tel);
  Future<String?> getTelephone() => _storage.read(key: _telephoneKey);

  Future<void> saveStatus(String status) => _storage.write(key: _statusKey, value: status);
  Future<String?> getStatus() => _storage.read(key: _statusKey);

  Future<void> savePrenom(String prenom) => _storage.write(key: _prenomKey, value: prenom);
  Future<String?> getPrenom() => _storage.read(key: _prenomKey);

  Future<void> saveNom(String nom) => _storage.write(key: _nomKey, value: nom);
  Future<String?> getNom() => _storage.read(key: _nomKey);

  Future<void> saveExpiresIn(DateTime expiresIn) =>
      _storage.write(key: _expiresInKey, value: expiresIn.toIso8601String());

  Future<DateTime?> getExpiresIn() async {
    final raw = await _storage.read(key: _expiresInKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// Retourne `true` si le token est expiré ou si aucune info d'expiration n'est disponible.
  Future<bool> isTokenExpired() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return true;
    final expiresIn = await getExpiresIn();
    if (expiresIn == null) return false; // pas d'info → on suppose valide
    return DateTime.now().isAfter(expiresIn);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
