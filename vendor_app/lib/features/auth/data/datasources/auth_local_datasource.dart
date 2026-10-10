import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shop/data/models/shop_model.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearUser();
  Future<void> cacheBoutique(ShopModel boutique);
  Future<ShopModel?> getCachedBoutique();
  Future<void> clearBoutique();
}

@Injectable(as: AuthLocalDataSource)
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String _userKey = 'cached_user';
  static const String _boutiqueKey = 'cached_boutique';
  final SharedPreferences _prefs;
  const AuthLocalDataSourceImpl(this._prefs);

  @override
  Future<void> cacheUser(UserModel user) async {
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final json = _prefs.getString(_userKey);
    if (json == null) return null;
    return UserModel.fromJson(jsonDecode(json));
  }

  @override
  Future<void> clearUser() => _prefs.remove(_userKey);

  @override
  Future<void> cacheBoutique(ShopModel boutique) async {
    await _prefs.setString(_boutiqueKey, jsonEncode(boutique.toJson()));
  }

  @override
  Future<ShopModel?> getCachedBoutique() async {
    final json = _prefs.getString(_boutiqueKey);
    if (json == null) return null;
    return ShopModel.fromJson(jsonDecode(json));
  }

  @override
  Future<void> clearBoutique() => _prefs.remove(_boutiqueKey);
}
