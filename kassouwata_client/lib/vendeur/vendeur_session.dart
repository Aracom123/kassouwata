import 'package:dio/dio.dart';

import '../core/storage/secure_storage.dart';
import '../espaces/espace.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/models/personne_model.dart';
import 'features/auth/data/models/profile_model.dart';
import 'features/auth/data/models/user_model.dart';
import 'features/shop/data/datasources/shop_remote_datasource.dart';
import 'features/shop/data/models/shop_model.dart';
import 'shared/enums/user_status.dart';

/// Espace vendeur de l'application unique.
///
/// Le profil renvoyé à la connexion (CLIENT / VENDEUR) décide des écrans
/// affichés. Pour un vendeur, on garde en cache l'utilisateur et sa boutique,
/// utilisés par les écrans « Ma boutique » (tableau de bord, produits,
/// commandes reçues, paramètres).
class VendeurSession {
  static const String profilVendeur = 'VENDEUR';

  final AuthLocalDataSource _local;
  final ShopRemoteDataSource _shop;
  final SecureStorage _storage;

  VendeurSession(this._local, this._shop, this._storage);

  static bool estVendeur(String? profile) =>
      (profile ?? '').trim().toUpperCase() == profilVendeur;

  Future<bool> estConnecteCommeVendeur() async =>
      estVendeur(await _storage.getProfile());

  /// Appelé après chaque connexion réussie, quel que soit le profil :
  /// remplace le cache de la session précédente.
  Future<void> enregistrerConnexion({
    required String idUser,
    required String telephone,
    required String profile,
    required String status,
    String? nom,
    String? prenom,
    String? email,
    Map<String, dynamic>? boutique,
  }) async {
    await effacer();
    if (!estVendeur(profile)) return;

    PersonneModel? personne;
    ProfileModel? profil;
    try {
      final vendeur = boutique?['vendeur'] as Map<String, dynamic>?;
      final p = vendeur?['personne'] as Map<String, dynamic>?;
      if (p != null) personne = PersonneModel.fromJson(p);
      final pr = vendeur?['profile'] as Map<String, dynamic>?;
      if (pr != null) profil = ProfileModel.fromJson(pr);
    } catch (_) {}
    personne ??= (nom != null || prenom != null)
        ? PersonneModel(
            idPersonne: '', nom: nom ?? '', prenom: prenom ?? '', email: email)
        : null;

    await _local.cacheUser(UserModel(
      idUser: idUser,
      telephone: telephone,
      status: UserStatus.fromJson(status),
      personne: personne,
      profile: profil,
    ));

    if (boutique != null) {
      try {
        await _local.cacheBoutique(ShopModel.fromJson(boutique));
      } catch (_) {}
    }
  }

  /// Boutique du vendeur connecté (cache, sinon serveur). `null` si le vendeur
  /// n'a pas encore créé sa boutique.
  Future<ShopModel?> boutique({bool rafraichir = false}) async {
    if (!rafraichir) {
      final cached = await _local.getCachedBoutique();
      if (cached != null) return cached;
    }
    final idUser = await _storage.getUserId();
    if (idUser == null || idUser.isEmpty) return null;
    try {
      final b = await _shop.getBoutiqueByVendeur(idUser);
      await _local.cacheBoutique(b);
      return b;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    } catch (e) {
      // Seul un 404 signifie « pas de boutique ». Toute autre erreur est
      // remontée : surtout ne pas inviter à créer une deuxième boutique.
      if (e.toString().contains('404')) return null;
      rethrow;
    }
  }

  /// Page à ouvrir après connexion : un vendeur sans boutique est invité à la
  /// créer ; sinon le dernier espace utilisé (ou l'écran de choix).
  Future<String> accueilApresConnexion() async {
    if (!await estConnecteCommeVendeur()) {
      if (EspaceService.dernier() == Espace.vendeur) {
        await EspaceService.memoriser(Espace.acheteur);
      }
      return EspaceService.accueil();
    }
    try {
      return await boutique() == null ? '/creer-boutique' : EspaceService.accueil();
    } catch (_) {
      return EspaceService.accueil();
    }
  }

  /// Après la création de sa boutique, un client devient vendeur (le backend
  /// change son profil) : on met la session locale à jour.
  Future<void> marquerVendeur() async {
    await _storage.saveProfile(profilVendeur);
    if (await _local.getCachedUser() == null) {
      final prenom = await _storage.getPrenom();
      final nom = await _storage.getNom();
      await _local.cacheUser(UserModel(
        idUser: await _storage.getUserId() ?? '',
        telephone: await _storage.getTelephone() ?? '',
        status: UserStatus.active,
        personne: (prenom != null || nom != null)
            ? PersonneModel(idPersonne: '', nom: nom ?? '', prenom: prenom ?? '')
            : null,
      ));
    }
  }

  Future<void> effacer() async {
    await _local.clearUser();
    await _local.clearBoutique();
  }
}
