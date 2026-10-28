class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/api/authenticate';
  static const String register = '/api/nosUsers/register';
  static const String sendOtp = '/api/nosUsers/send-otp';
  static const String verifyOtp = '/api/nosUsers/verify-otp';
  static const String forgotPassword = '/api/nosUsers/forgot-password';
  static const String resetPassword = '/api/nosUsers/reset-password';
  static const String logout = '/api/nosUsers/logout';
  static const String me = '/api/nosUsers/me';
  static String updateUser(String id) => '/api/nosUsers/update/$id';
  static String userById(String id) => '/api/nosUsers/$id';
  static String userByTelephone(String telephone) => '/api/nosUsers/get/$telephone';

  // Boutique (Shop)
  static const String saveBoutique = '/api/nosBoutiques/save';
  static String updateBoutique(String id) => '/api/nosBoutiques/update/$id';
  static const String listBoutiques = '/api/nosBoutiques/list';
  static String boutiqueById(String id) => '/api/nosBoutiques/$id';
  static String boutiqueByVendeur(String idUser) => '/api/nosBoutiques/byVendeur/$idUser';

  // Produits
  static const String produits = '/api/nosProduits';
  static String produitById(String id) => '/api/nosProduits/$id';
  static String produitsByBoutique(int idBoutique) => '/api/nosProduits/getByBoutiqueId/$idBoutique';
  static const String saveProduit = '/api/nosProduits/save';
  static String updateProduit(int id) => '/api/nosProduits/update/$id';
  static String deleteProduit(int id) => '/api/nosProduits/delete/$id';

  // Upload fichiers
  static const String uploadImage = '/api/files/upload';
  static const String uploadImages = '/api/files/upload-many';
  static String deleteFile(String filename) => '/api/files/delete?filename=$filename';
  static String imageUrl(String baseUrl, String filename) => '$baseUrl/images/$filename';

  // Commandes
  static const String commandes = '/api/nosCommandes';
  static String commandeById(int id) => '/api/nosCommandes/$id';
  static String commandesByBoutique(int idBoutique) => '/api/nosCommandes/byBoutique/$idBoutique';
  static String updateCommandeStatut(int id) => '/api/nosCommandes/$id/statut';

  // Paiements en ligne (agrégateur : Mobile Money, STA, carte)
  static const String moyensPaiement = '/api/payment/moyens';
  static const String payer = '/api/payment/mobile-money';
  static String statutPaiement(String reference) =>
      '/api/payment/statut/$reference';
  static String resumePaiementCommande(int idCommande) =>
      '/api/payment/commande/$idCommande/resume';

  // Tontines
  static const String tontines = '/api/nosTontines/list';
  static const String saveTontine = '/api/nosTontines/save';
  static String tontineById(int id) => '/api/nosTontines/$id';
  static String updateTontineById(int id) => '/api/nosTontines/update/$id';
  static String deleteTontineById(int id) => '/api/nosTontines/delete/$id';

  // Périodes de versement (contrôleur séparé)
  static const String periodes = '/api/nosTontinePeriodeVersements/list';
  static const String savePeriode = '/api/nosTontinePeriodeVersements/save';
  static String updatePeriodeById(int id) =>
      '/api/nosTontinePeriodeVersements/update/$id';
  static String deletePeriodeById(int id) =>
      '/api/nosTontinePeriodeVersements/delete/$id';

  // Versements (contrôleur séparé, UUID comme ID)
  static const String versements = '/api/nosTontineVersements/list';
  static const String saveVersement = '/api/nosTontineVersements/save';
  static String updateVersementById(String id) =>
      '/api/nosTontineVersements/update/$id';
  static String deleteVersementById(String id) =>
      '/api/nosTontineVersements/delete/$id';

  // Demandes d'adhésion
  static const String demandesAdhesion = '/api/nosDemandesAdhesion/list';
  static const String saveDemandeAdhesion = '/api/nosDemandesAdhesion/save';
  static String updateDemandeAdhesionById(int id) =>
      '/api/nosDemandesAdhesion/update/$id';
  static String deleteDemandeAdhesionById(int id) =>
      '/api/nosDemandesAdhesion/delete/$id';

  // Catégories
  static const String categories = '/api/nosCategories/list';
}