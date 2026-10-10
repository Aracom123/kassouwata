package com.techinnov.kassouwata_back.entitites;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import lombok.Data;

/**
 * Catégorie (type) de paiement affichée au client avant le choix du fournisseur.
 *
 * Codes utilisés par le backend pour construire la requête KomiPay :
 *   MOBILE_MONEY : opérateurs télécoms (corps avec nom_prenom_payeur, numéro local)
 *   STA          : sociétés de transfert d'argent (corps avec pays_payeur, numéro international)
 *   CARTE        : cartes bancaires Visa / MasterCard (chiffrement CVV + 3DS)
 */
@Data
@Entity
public class CategoriePaiement extends Auditable<String> {

    public static final String MOBILE_MONEY = "MOBILE_MONEY";
    public static final String STA = "STA";
    public static final String CARTE = "CARTE";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long idCategoriePaiement;

    @Column(nullable = false, unique = true, length = 30)
    private String code;

    private String libelle;

    private String description;

    private Integer ordre = 0;

    private Boolean actif = true;
}
