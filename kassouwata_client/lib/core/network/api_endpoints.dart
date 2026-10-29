class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/api/authenticate';
  static const String register = '/api/nosUsers/register';
  static const String sendOtp = '/api/nosUsers/send-otp';
  static const String verifyOtp = '/api/nosUsers/verify-otp';
  static const String forgotPassword = '/api/nosUsers/forgot-password';
  static const String resetPassword = '/api/nosUsers/reset-password';
  static const String me = '/api/nosUsers/me';
  static const String users = '/api/nosUsers/list';
  static const String profiles = '/api/nosProfiles/list';
  static String updateUser(String id) => '/api/nosUsers/update/$id';
  static String completeProfile(String id) => '/api/nosUsers/complete-profile/$id';
  static const String refreshToken = '/api/nosUsers/refresh-token';
  // Changement de numéro (code envoyé au nouveau numéro)
  static const String changeTelephoneDemande = '/api/nosUsers/change-telephone/demande';
  static const String changeTelephoneConfirmation =
      '/api/nosUsers/change-telephone/confirmation';

  // Produits — catalogue public : uniquement les boutiques au statut ACTIVE
  static const String produits = '/api/nosProduits/catalogue';
  static String produitById(int id) => '/api/nosProduits/catalogue/$id';

  // Catégories
  static const String categories = '/api/nosCategories/list';

  // Commandes
  static const String commandes = '/api/nosCommandes/list';
  static String commandesByClient(String userId) => '/api/nosCommandes/byClient/$userId';
  static const String saveCommande = '/api/nosCommandes/save';
  static String commandeById(int id) => '/api/nosCommandes/$id';
  static String cancelCommande(int id) => '/api/nosCommandes/cancel/$id';

  // Lignes de commande (ProduitCommande)
  static const String saveProduitCommande = '/api/nosProduitsCommandes/save';

  // Versements (paiement par tranche)
  static const String saveVersementCommande = '/api/nosTransactions/save';
  static String versementsByCommande(int id) =>
      '/api/nosTransactions/byCommande/$id';

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

  // Tontines — demandes d'adhésion
  static const String demandesAdhesion = '/api/nosDemandesAdhesion/list';
  // Adashé Produit (achat groupé d'un produit)
  static const String adasheProduit = '/api/nosTontines/produit';
  static String adasheProduitResume(int idTontine) => '/api/nosTontines/produit/$idTontine';
  static String adasheProduitOuverts(int idProduit) =>
      '/api/nosTontines/produit/de-produit/$idProduit';
  static String adasheProduitRejoindre(int idTontine) =>
      '/api/nosTontines/produit/$idTontine/rejoindre';
  static String adasheProduitDecision(int idTontine) =>
      '/api/nosTontines/produit/$idTontine/decision';
  static String adasheProduitBoutique(int idBoutique) =>
      '/api/nosTontines/produit/boutique/$idBoutique';

  /// Demandes reçues par l'utilisateur connecté (rattachées à son compte)
  static const String mesDemandesAdhesion = '/api/nosDemandesAdhesion/mes-demandes';
  static const String saveDemandeAdhesion = '/api/nosDemandesAdhesion/save';
  static String updateDemandeAdhesion(int id) =>
      '/api/nosDemandesAdhesion/update/$id';

  // Périodes de versement
  static const String periodes = '/api/nosTontinePeriodeVersements/list';
  static const String savePeriode = '/api/nosTontinePeriodeVersements/save';

  // Versements (cotisations)
  static const String versements = '/api/nosTontineVersements/list';
  static const String saveVersement = '/api/nosTontineVersements/save';

  // Boutiques
  static const String boutiques = '/api/nosBoutiques/actives';
  static String boutiqueById(int id) => '/api/nosBoutiques/$id';
  static String produitsByBoutique(int id) =>
      '/api/nosProduits/catalogue/boutique/$id';

  // Images
  static String imageUrl(String baseUrl, String filename) =>
      '$baseUrl/images/$filename';
}
