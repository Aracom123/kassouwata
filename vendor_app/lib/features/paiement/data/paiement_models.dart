import '../../../core/config/app_config.dart';

/// Codes de catégorie renvoyés par GET /api/payment/moyens.
class CodesCategorie {
  CodesCategorie._();
  static const mobileMoney = 'MOBILE_MONEY';
  static const sta = 'STA';
  static const carte = 'CARTE';
}

/// Objet payé (côté backend : TypeOperationPaiement).
enum TypeOperationPaiement { commande, tontine }

extension TypeOperationPaiementX on TypeOperationPaiement {
  String get code => this == TypeOperationPaiement.commande ? 'COMMANDE' : 'TONTINE';
}

/// Statut d'une transaction côté backend.
enum StatutPaiement { enAttente, reussie, echouee }

StatutPaiement statutDepuisCode(String? code) {
  switch ((code ?? '').toUpperCase()) {
    case 'REUSSIE':
      return StatutPaiement.reussie;
    case 'ECHOUEE':
      return StatutPaiement.echouee;
    default:
      return StatutPaiement.enAttente;
  }
}

/// Moyen de paiement (Airtel Money, MyNita, Visa...).
class MoyenPaiement {
  final int id;
  final String code;
  final String libelle;
  final String? logoPath;
  final String categorieCode;

  const MoyenPaiement({
    required this.id,
    required this.code,
    required this.libelle,
    required this.categorieCode,
    this.logoPath,
  });

  /// URL complète du logo : <BASE_URL>/api + logoPath.
  String? get logoUrl =>
      logoPath == null || logoPath!.isEmpty ? null : '${AppConfig.baseUrl}/api$logoPath';

  factory MoyenPaiement.fromJson(Map<String, dynamic> json) => MoyenPaiement(
        id: (json['idMoyenPaiement'] as num?)?.toInt() ?? 0,
        code: json['code'] as String? ?? '',
        libelle: json['libelle'] as String? ?? '',
        logoPath: json['logoPath'] as String?,
        categorieCode: json['categorieCode'] as String? ?? '',
      );
}

/// Catégorie de paiement (Mobile Money, STA, Carte) avec ses moyens actifs.
class CategoriePaiement {
  final String code;
  final String libelle;
  final String? description;
  final List<MoyenPaiement> moyens;

  const CategoriePaiement({
    required this.code,
    required this.libelle,
    this.description,
    this.moyens = const [],
  });

  bool get estCarte => code == CodesCategorie.carte;

  factory CategoriePaiement.fromJson(Map<String, dynamic> json) => CategoriePaiement(
        code: json['code'] as String? ?? '',
        libelle: json['libelle'] as String? ?? '',
        description: json['description'] as String?,
        moyens: (json['moyens'] as List<dynamic>? ?? [])
            .map((e) => MoyenPaiement.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Réponse de POST /api/payment/mobile-money ou GET /api/payment/statut/{ref}.
class ResultatPaiement {
  final int? idTransaction;
  final String referenceExterne;
  final StatutPaiement statut;
  final String? message;
  final String? moyenPaiement;
  final double? montant;

  /// Carte avec défi 3DS : lien du portail d'authentification de la banque.
  final String? lienAuthentification;

  const ResultatPaiement({
    required this.referenceExterne,
    required this.statut,
    this.idTransaction,
    this.message,
    this.moyenPaiement,
    this.montant,
    this.lienAuthentification,
  });

  factory ResultatPaiement.fromJson(Map<String, dynamic> json) => ResultatPaiement(
        idTransaction: (json['idTransaction'] as num?)?.toInt(),
        referenceExterne: json['referenceExterne'] as String? ?? '',
        statut: statutDepuisCode(json['statut'] as String?),
        message: json['message'] as String?,
        moyenPaiement: json['moyenPaiement'] as String?,
        montant: (json['montant'] as num?)?.toDouble(),
        lienAuthentification: json['lienAuthentification'] as String?,
      );

  ResultatPaiement copyWith({StatutPaiement? statut, String? message}) => ResultatPaiement(
        idTransaction: idTransaction,
        referenceExterne: referenceExterne,
        statut: statut ?? this.statut,
        message: message ?? this.message,
        moyenPaiement: moyenPaiement,
        montant: montant,
        lienAuthentification: lienAuthentification,
      );
}

/// Paramètres de l'écran de paiement (passés via GoRouter `extra`).
class PaiementArgs {
  final TypeOperationPaiement typeOperation;

  /// Id de la commande ou de la tontine payée.
  final int operationId;

  /// Montant proposé (FCFA).
  final double montant;

  /// Le client peut-il modifier le montant (versement par tranche) ?
  final bool montantModifiable;

  /// Montant maximum autorisé (reste à payer) quand le montant est modifiable.
  final double? montantMax;

  /// Tontine : période de cotisation payée.
  final int? periodeVersementId;

  final String titre;
  final String? sousTitre;

  const PaiementArgs({
    required this.typeOperation,
    required this.operationId,
    required this.montant,
    required this.titre,
    this.montantModifiable = false,
    this.montantMax,
    this.periodeVersementId,
    this.sousTitre,
  });
}

/// Résultat renvoyé par l'écran de paiement à la page appelante (context.push).
class IssuePaiement {
  final StatutPaiement statut;
  final String? referenceExterne;
  const IssuePaiement(this.statut, [this.referenceExterne]);

  bool get reussi => statut == StatutPaiement.reussie;
}
